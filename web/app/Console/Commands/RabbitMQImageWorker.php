<?php

namespace App\Console\Commands;

use App\Services\ImageFetchHandler;
use App\Services\RabbitMQService;
use Illuminate\Console\Command;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Log;
use PhpAmqpLib\Message\AMQPMessage;

class RabbitMQImageWorker extends Command
{
    /**
     * The name and signature of the console command.
     */
    protected $signature = 'rabbitmq:image-worker';

    /**
     * The console command description.
     */
    protected $description = 'Process image fetch requests from RabbitMQ queue';

    private RabbitMQService $rabbitMQ;
    private ImageFetchHandler $imageHandler;

    public function __construct(RabbitMQService $rabbitMQ, ImageFetchHandler $imageHandler)
    {
        parent::__construct();
        $this->rabbitMQ = $rabbitMQ;
        $this->imageHandler = $imageHandler;
    }

    /**
     * Execute the console command.
     */
    public function handle(): int
    {
        $this->info('Starting RabbitMQ image fetch worker...');

        pcntl_async_signals(true);

        pcntl_signal(SIGTERM, function (): void {
            $this->info('Received SIGTERM, shutting down...');
            $this->rabbitMQ->close();
            exit(0);
        });

        pcntl_signal(SIGINT, function (): void {
            $this->info('Received SIGINT, shutting down...');
            $this->rabbitMQ->close();
            exit(0);
        });

        $callback = function (AMQPMessage $message): void {
            $this->processMessage($message);
        };

        $this->rabbitMQ->consumeImageFetchQueue($callback);

        return Command::SUCCESS;
    }

    /**
     * Process a single image fetch message.
     */
    private function processMessage(AMQPMessage $message): void
    {
        $body = json_decode($message->getBody(), true);

        if (!isset($body['file_id'])) {
            Log::warning('RabbitMQ: Received message without file_id');
            $this->rabbitMQ->publishImageResponse($message, [
                'success' => false,
                'error' => 'Missing file_id',
            ]);
            $this->rabbitMQ->ack($message);
            return;
        }

        $fileId = $body['file_id'];
        $this->info("Processing image: {$fileId}");

        $cacheKey = "gdrive_image_{$fileId}";
        $cachedData = Cache::get($cacheKey);

        if ($cachedData !== null) {
            $this->info("Cache hit for: {$fileId}");
            $this->rabbitMQ->publishImageResponse($message, $cachedData);
            $this->rabbitMQ->ack($message);
            return;
        }

        $imageData = $this->imageHandler->fetch($fileId);

        if ($imageData === null) {
            $this->warn("Failed to fetch image: {$fileId}");
            $this->rabbitMQ->publishImageResponse($message, [
                'success' => false,
                'error' => 'Failed to fetch image from Google Drive',
            ]);
            $this->rabbitMQ->ack($message);
            return;
        }

        Cache::put($cacheKey, $imageData, 31536000); // 1 year

        $this->info("Successfully fetched and cached: {$fileId}");
        $this->rabbitMQ->publishImageResponse($message, $imageData);
        $this->rabbitMQ->ack($message);
    }
}
