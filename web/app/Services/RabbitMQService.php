<?php

namespace App\Services;

use PhpAmqpLib\Channel\AMQPChannel;
use PhpAmqpLib\Connection\AMQPStreamConnection;
use PhpAmqpLib\Message\AMQPMessage;
use Illuminate\Support\Facades\Log;

class RabbitMQService
{
    private ?AMQPStreamConnection $connection = null;
    private ?AMQPChannel $channel = null;
    private array $config;

    public function __construct()
    {
        $this->config = config('rabbitmq');
    }

    /**
     * Get or create the AMQP connection.
     */
    public function getConnection(): AMQPStreamConnection
    {
        if ($this->connection === null || !$this->connection->isConnected()) {
            $this->connection = new AMQPStreamConnection(
                $this->config['host'],
                $this->config['port'],
                $this->config['user'],
                $this->config['password'],
                $this->config['vhost'],
                false,
                'AMQPLAIN',
                null,
                'en_US',
                $this->config['connection_timeout'],
                $this->config['read_write_timeout'],
                null,
                false,
                $this->config['heartbeat']
            );
        }

        return $this->connection;
    }

    /**
     * Get or create the AMQP channel.
     */
    public function getChannel(): AMQPChannel
    {
        if ($this->channel === null || !$this->channel->is_open()) {
            $this->channel = $this->getConnection()->channel();
        }

        return $this->channel;
    }

    /**
     * Declare the image fetch queue.
     */
    public function declareImageFetchQueue(): void
    {
        $queueConfig = $this->config['queues']['image_fetch'];
        $channel = $this->getChannel();

        $channel->queue_declare(
            $queueConfig['name'],
            false,
            $queueConfig['durable'],
            $queueConfig['exclusive'],
            $queueConfig['auto_delete']
        );
    }

    /**
     * Declare the image upload queue.
     */
    public function declareImageUploadQueue(): void
    {
        $queueConfig = $this->config['queues']['image_upload'];
        $channel = $this->getChannel();

        $channel->queue_declare(
            $queueConfig['name'],
            false,
            $queueConfig['durable'],
            $queueConfig['exclusive'],
            $queueConfig['auto_delete']
        );
    }

    /**
     * Perform an RPC call to fetch an image.
     * Returns the image data or null on failure/timeout.
     */
    public function rpcImageFetch(string $fileId): ?array
    {
        $channel = $this->getChannel();
        $queueConfig = $this->config['queues']['image_fetch'];
        $rpcConfig = $this->config['rpc'];

        $this->declareImageFetchQueue();

        $correlationId = uniqid('rpc_', true);
        $response = null;
        $responseReceived = false;

        list($replyQueue, ,) = $channel->queue_declare(
            '',
            false,
            false,
            true,
            true
        );

        $callback = function (AMQPMessage $message) use ($correlationId, &$response, &$responseReceived): void {
            if ($message->get('correlation_id') === $correlationId) {
                $response = json_decode($message->getBody(), true);
                $responseReceived = true;
            }
        };

        $channel->basic_consume(
            $replyQueue,
            '',
            false,
            true,
            false,
            false,
            $callback
        );

        $requestBody = json_encode(['file_id' => $fileId]);
        $message = new AMQPMessage($requestBody, [
            'correlation_id' => $correlationId,
            'reply_to' => $replyQueue,
            'delivery_mode' => AMQPMessage::DELIVERY_MODE_PERSISTENT,
        ]);

        $channel->basic_publish($message, '', $queueConfig['name']);

        $startTime = time();
        $timeout = $rpcConfig['timeout'];

        while (!$responseReceived) {
            $channel->wait(null, false, $timeout);

            if ((time() - $startTime) >= $timeout) {
                Log::warning("RabbitMQ RPC timeout for image: {$fileId}");
                break;
            }
        }

        return $response;
    }

    /**
     * Perform an RPC call to upload an image.
     * Returns the upload result or null on failure/timeout.
     */
    public function rpcImageUpload(array $payload): ?array
    {
        $channel = $this->getChannel();
        $queueConfig = $this->config['queues']['image_upload'];
        $rpcConfig = $this->config['rpc'];

        $this->declareImageUploadQueue();

        $correlationId = uniqid('rpc_upload_', true);
        $response = null;
        $responseReceived = false;

        list($replyQueue, ,) = $channel->queue_declare(
            '',
            false,
            false,
            true,
            true
        );

        $callback = function (AMQPMessage $message) use ($correlationId, &$response, &$responseReceived): void {
            if ($message->get('correlation_id') === $correlationId) {
                $response = json_decode($message->getBody(), true);
                $responseReceived = true;
            }
        };

        $channel->basic_consume(
            $replyQueue,
            '',
            false,
            true,
            false,
            false,
            $callback
        );

        $requestBody = json_encode($payload);
        $message = new AMQPMessage($requestBody, [
            'correlation_id' => $correlationId,
            'reply_to' => $replyQueue,
            'delivery_mode' => AMQPMessage::DELIVERY_MODE_PERSISTENT,
        ]);

        $channel->basic_publish($message, '', $queueConfig['name']);

        $startTime = time();
        $timeout = $rpcConfig['timeout'];

        while (!$responseReceived) {
            $channel->wait(null, false, $timeout);

            if ((time() - $startTime) >= $timeout) {
                Log::warning("RabbitMQ RPC upload timeout");
                break;
            }
        }

        return $response;
    }

    /**
     * Publish an image fetch response (used by worker).
     */
    public function publishImageResponse(AMQPMessage $request, array $data): void
    {
        $channel = $this->getChannel();
        $replyTo = $request->get('reply_to');
        $correlationId = $request->get('correlation_id');

        $responseMessage = new AMQPMessage(json_encode($data), [
            'correlation_id' => $correlationId,
        ]);

        $channel->basic_publish($responseMessage, '', $replyTo);
    }

    /**
     * Start consuming from the image fetch queue (used by worker).
     */
    public function consumeImageFetchQueue(callable $callback): void
    {
        $channel = $this->getChannel();
        $queueConfig = $this->config['queues']['image_fetch'];

        $this->declareImageFetchQueue();

        $channel->basic_qos(0, 1, false);

        $channel->basic_consume(
            $queueConfig['name'],
            '',
            false,
            false,
            false,
            false,
            $callback
        );

        Log::info('RabbitMQ worker started, waiting for image fetch requests...');

        while ($channel->is_consuming()) {
            $channel->wait();
        }
    }

    /**
     * Start consuming from the image upload queue (used by worker).
     */
    public function consumeImageUploadQueue(callable $callback): void
    {
        $channel = $this->getChannel();
        $queueConfig = $this->config['queues']['image_upload'];

        $this->declareImageUploadQueue();

        $channel->basic_qos(0, 1, false);

        $channel->basic_consume(
            $queueConfig['name'],
            '',
            false,
            false,
            false,
            false,
            $callback
        );

        Log::info('RabbitMQ worker started, waiting for image upload requests...');

        while ($channel->is_consuming()) {
            $channel->wait();
        }
    }

    /**
     * Acknowledge a message.
     */
    public function ack(AMQPMessage $message): void
    {
        $message->ack();
    }

    /**
     * Close the connection.
     */
    public function close(): void
    {
        if ($this->channel !== null && $this->channel->is_open()) {
            $this->channel->close();
        }

        if ($this->connection !== null && $this->connection->isConnected()) {
            $this->connection->close();
        }

        $this->channel = null;
        $this->connection = null;
    }

    public function __destruct()
    {
        $this->close();
    }
}
