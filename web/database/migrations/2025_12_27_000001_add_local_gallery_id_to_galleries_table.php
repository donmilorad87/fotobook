<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     *
     * Adds local_gallery_id column to galleries table.
     * This stores the desktop app's local database ID for automatic
     * order-to-gallery matching when orders are fetched.
     */
    public function up(): void
    {
        Schema::table('galleries', function (Blueprint $table) {
            $table->unsignedBigInteger('local_gallery_id')->nullable()->after('google_drive_folder_id');

            // Index for faster lookups when matching orders to local galleries
            $table->index(['user_id', 'local_gallery_id']);
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('galleries', function (Blueprint $table) {
            $table->dropIndex(['user_id', 'local_gallery_id']);
            $table->dropColumn('local_gallery_id');
        });
    }
};
