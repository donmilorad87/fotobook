<?php

namespace App\Console\Commands;

use App\Services\ImageUploadHandler;
use App\Services\RabbitMQService;
use Illuminate\Console\Command;
use Illuminate\Support\Facades\Log;
use PhpAmqpLib\Message\AMQPMessage;

class RabbitMQUploadWorker extends Command
{
    /**
     * The name and signature of the console command.
     */
    protected $signature = 'rabbitmq:upload-worker';

    /**
     * The console command description.
     */
    protected $description = 'Process image upload requests from RabbitMQ queue';

    private RabbitMQService $rabbitMQ;
    private ImageUploadHandler $uploadHandler;

    public function __construct(RabbitMQService $rabbitMQ, ImageUploadHandler $uploadHandler)
    {
        parent::__construct();
        $this->rabbitMQ = $rabbitMQ;
        $this->uploadHandler = $uploadHandler;
    }

    /**
     * Execute the console command.
     */
    public function handle(): int
    {
        $this->info('Starting RabbitMQ image upload worker...');

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

        $this->rabbitMQ->consumeImageUploadQueue($callback);

        return Command::SUCCESS;
    }

    /**
     * Process a single image upload message.
     */
    private function processMessage(AMQPMessage $message): void
    {
        $body = json_decode($message->getBody(), true);

        $userId = $body['user_id'] ?? null;
        $galleryId = $body['gallery_id'] ?? null;
        $filename = $body['filename'] ?? null;

        if ($userId === null || $galleryId === null || $filename === null) {
            Log::warning('RabbitMQ: Upload message missing required fields');
            $this->rabbitMQ->publishImageResponse($message, [
                'success' => false,
                'error' => 'Missing required fields',
            ]);
            $this->rabbitMQ->ack($message);
            return;
        }

        $this->info("Processing upload: {$filename} for gallery {$galleryId}");

        $result = $this->uploadHandler->handle($body);

        if ($result['success']) {
            $this->info("Successfully uploaded: {$filename}");
        } else {
            $this->warn("Failed to upload: {$filename} - {$result['error']}");
        }

        $this->rabbitMQ->publishImageResponse($message, $result);
        $this->rabbitMQ->ack($message);
    }
}
