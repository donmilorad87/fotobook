<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class Picture extends Model
{
    use HasFactory;

    protected $fillable = [
        'gallery_id',
        'original_filename',
        'google_drive_url',
        'google_drive_file_id',
        'order_index',
    ];

    protected $casts = [
        'order_index' => 'integer',
    ];

    /**
     * Get the gallery that owns this picture.
     */
    public function gallery(): BelongsTo
    {
        return $this->belongsTo(Gallery::class);
    }

    /**
     * Check if this picture has been uploaded to Google Drive.
     */
    public function isUploaded(): bool
    {
        return !empty($this->google_drive_url);
    }

    /**
     * Get the Google Drive file ID for this picture.
     */
    public function getFileIdAttribute(): ?string
    {
        if ($this->google_drive_file_id) {
            return $this->google_drive_file_id;
        }

        // Fallback: extract file ID from URL
        if ($this->google_drive_url) {
            return self::extractFileId($this->google_drive_url);
        }

        return null;
    }

    /**
     * Get the display URL for this picture.
     * Returns placeholder - actual images loaded via JS from Google Drive API.
     */
    public function getDisplayUrlAttribute(): string
    {
        return '/images/placeholder.jpg';
    }

    /**
     * Extract Google Drive file ID from URL.
     */
    public static function extractFileId(string $url): ?string
    {
        if (preg_match('/[?&]id=([^&]+)/', $url, $matches)) {
            return $matches[1];
        }
        return null;
    }
}
