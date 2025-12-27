<?php

return [
    /*
    |--------------------------------------------------------------------------
    | RabbitMQ Connection Settings
    |--------------------------------------------------------------------------
    |
    | Configure the connection to your RabbitMQ server. These settings
    | control how the application connects to the message broker.
    |
    */

    'host' => env('RABBITMQ_HOST', 'localhost'),
    'port' => (int) env('RABBITMQ_PORT', 5672),
    'user' => env('RABBITMQ_USER', 'guest'),
    'password' => env('RABBITMQ_PASSWORD', 'guest'),
    'vhost' => env('RABBITMQ_VHOST', '/'),

    /*
    |--------------------------------------------------------------------------
    | Connection Options
    |--------------------------------------------------------------------------
    |
    | Advanced connection options for the AMQP connection.
    |
    */

    'connection_timeout' => (float) env('RABBITMQ_CONNECTION_TIMEOUT', 10.0),
    'read_write_timeout' => (float) env('RABBITMQ_READ_WRITE_TIMEOUT', 30.0),
    'heartbeat' => (int) env('RABBITMQ_HEARTBEAT', 60),

    /*
    |--------------------------------------------------------------------------
    | Queue Settings
    |--------------------------------------------------------------------------
    |
    | Settings for the image fetch queue and RPC operations.
    |
    */

    'queues' => [
        'image_fetch' => [
            'name' => env('RABBITMQ_IMAGE_QUEUE', 'image_fetch_queue'),
            'durable' => true,
            'auto_delete' => false,
            'exclusive' => false,
        ],
        'image_upload' => [
            'name' => env('RABBITMQ_UPLOAD_QUEUE', 'image_upload_queue'),
            'durable' => true,
            'auto_delete' => false,
            'exclusive' => false,
        ],
    ],

    /*
    |--------------------------------------------------------------------------
    | RPC Settings
    |--------------------------------------------------------------------------
    |
    | Settings for Remote Procedure Call operations.
    |
    */

    'rpc' => [
        'timeout' => (int) env('RABBITMQ_RPC_TIMEOUT', 30),
        'reply_queue_prefix' => 'rpc_reply_',
    ],
];
