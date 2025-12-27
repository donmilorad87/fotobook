<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Support\Str;

class Gallery extends Model
{
    use HasFactory;

    protected $fillable = [
        'user_id',
        'name',
        'slug',
        'google_drive_folder_id',
        'local_gallery_id',
    ];

    protected static function boot(): void
    {
        parent::boot();

        static::creating(function (Gallery $gallery) {
            if (empty($gallery->slug)) {
                $gallery->slug = static::generateUniqueSlug($gallery->name);
            }
        });
    }

    /**
     * Generate a unique slug for the gallery.
     */
    protected static function generateUniqueSlug(string $name): string
    {
        $baseSlug = Str::slug($name);
        $slug = $baseSlug . '-' . Str::random(8);

        while (static::where('slug', $slug)->exists()) {
            $slug = $baseSlug . '-' . Str::random(8);
        }

        return $slug;
    }

    /**
     * Get the user that owns the gallery.
     */
    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    /**
     * Get pictures in this gallery.
     */
    public function pictures(): HasMany
    {
        return $this->hasMany(Picture::class)->orderBy('order_index');
    }

    /**
     * Get orders for this gallery.
     */
    public function orders(): HasMany
    {
        return $this->hasMany(Order::class);
    }

    /**
     * Get the public URL for this gallery.
     */
    public function getPublicUrlAttribute(): string
    {
        return route('public.gallery', $this->slug);
    }

    /**
     * Get the cover image URL (first picture).
     */
    public function getCoverImageAttribute(): ?string
    {
        $firstPicture = $this->pictures()->first();
        return $firstPicture?->google_drive_url;
    }

    /**
     * Get the cover image file ID (first picture).
     */
    public function getCoverFileIdAttribute(): ?string
    {
        $firstPicture = $this->pictures()->first();
        return $firstPicture?->file_id;
    }

    /**
     * Get picture count.
     */
    public function getPictureCountAttribute(): int
    {
        return $this->pictures()->count();
    }

    /**
     * Get order count.
     */
    public function getOrderCountAttribute(): int
    {
        return $this->orders()->count();
    }
}
