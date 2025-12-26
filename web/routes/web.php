<?php

use App\Http\Controllers\Auth\GoogleAuthController;
use App\Http\Controllers\Auth\LoginController;
use App\Http\Controllers\Auth\RegisterController;
use App\Http\Controllers\DashboardController;
use App\Http\Controllers\DownloadController;
use App\Http\Controllers\GalleryController;
use App\Http\Controllers\ImageProxyController;
use App\Http\Controllers\OrderController;
use App\Http\Controllers\ProfileController;
use App\Http\Controllers\PublicGalleryController;
use Illuminate\Support\Facades\Route;

// Redirect root to login
Route::get('/', function () {
    return redirect()->route('login');
});

// Guest routes (not authenticated)
Route::middleware('guest')->group(function () {
    Route::get('/login', [LoginController::class, 'showLoginForm'])->name('login');
    Route::post('/login', [LoginController::class, 'login']);
    Route::get('/register', [RegisterController::class, 'showRegistrationForm'])->name('register');
    Route::post('/register', [RegisterController::class, 'register']);
});

// Logout (requires auth)
Route::post('/logout', [LoginController::class, 'logout'])->name('logout')->middleware('auth');

// Public gallery routes (no auth required)
Route::get('/gallery/{slug}', [PublicGalleryController::class, 'show'])->name('public.gallery');
Route::post('/gallery/{slug}/order', [PublicGalleryController::class, 'submitSelection'])->name('public.gallery.order');

// Image proxy for Google Drive (no auth required, images are already public)
Route::get('/image/{fileId}', [ImageProxyController::class, 'show'])->name('image.proxy');

// Authenticated routes
Route::middleware('auth')->group(function () {
    // Google OAuth
    Route::get('/google/connect', [GoogleAuthController::class, 'show'])->name('google.connect');
    Route::get('/google/redirect', [GoogleAuthController::class, 'redirect'])->name('google.redirect');
    Route::get('/google/callback', [GoogleAuthController::class, 'callback'])->name('google.callback');
    Route::post('/google/disconnect', [GoogleAuthController::class, 'disconnect'])->name('google.disconnect');

    // Routes requiring Google connection
    Route::middleware('google.connected')->group(function () {
        // Dashboard
        Route::get('/dashboard', [DashboardController::class, 'index'])->name('dashboard');

        // Download desktop app
        Route::get('/download', [DownloadController::class, 'index'])->name('download');

        // Galleries
        Route::get('/galleries', [GalleryController::class, 'index'])->name('galleries.index');
        Route::get('/galleries/{gallery}', [GalleryController::class, 'show'])->name('galleries.show');
        Route::delete('/galleries/{gallery}', [GalleryController::class, 'destroy'])->name('galleries.destroy');

        // Orders
        Route::get('/orders', [OrderController::class, 'index'])->name('orders.index');
        Route::get('/orders/{order}', [OrderController::class, 'show'])->name('orders.show');
        Route::get('/orders/{order}/export', [OrderController::class, 'exportJson'])->name('orders.export');

        // Profile
        Route::get('/profile', [ProfileController::class, 'edit'])->name('profile.edit');
        Route::put('/profile', [ProfileController::class, 'update'])->name('profile.update');
    });
});
