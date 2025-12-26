<?php

use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\GalleryController;
use App\Http\Controllers\Api\OrderController;
use Illuminate\Support\Facades\Route;

// Desktop app authentication (no token required)
Route::post('/auth/login', [AuthController::class, 'login']);

// Protected API routes (require API token)
Route::middleware('api.token')->group(function () {
    // Galleries
    Route::get('/galleries', [GalleryController::class, 'index']);
    Route::post('/galleries', [GalleryController::class, 'store']);
    Route::post('/galleries/{gallery}/images', [GalleryController::class, 'uploadImage']);
    Route::post('/galleries/{gallery}/finalize', [GalleryController::class, 'finalize']);

    // Orders
    Route::get('/orders', [OrderController::class, 'index']);
});
