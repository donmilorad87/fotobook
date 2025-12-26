<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Collection;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class Order extends Model
{
    use HasFactory;

    protected $fillable = [
        'gallery_id',
        'client_name',
        'client_email',
        'selected_picture_ids',
    ];

    protected $casts = [
        'selected_picture_ids' => 'array',
    ];

    /**
     * Get the gallery this order belongs to.
     */
    public function gallery(): BelongsTo
    {
        return $this->belongsTo(Gallery::class);
    }

    /**
     * Get the selected pictures as a collection.
     */
    public function getSelectedPicturesAttribute(): Collection
    {
        return Picture::whereIn('id', $this->selected_picture_ids ?? [])->get();
    }

    /**
     * Get the count of selected pictures.
     */
    public function getSelectedCountAttribute(): int
    {
        return count($this->selected_picture_ids ?? []);
    }

    /**
     * Get the photographer (gallery owner).
     */
    public function getPhotographerAttribute(): ?User
    {
        return $this->gallery?->user;
    }

    /**
     * Convert order to JSON export format for desktop app.
     */
    public function toExportArray(): array
    {
        $pictures = $this->selectedPictures;

        return [
            'order_id' => $this->id,
            'gallery_id' => $this->gallery_id,
            'gallery_name' => $this->gallery->name,
            'client_name' => $this->client_name,
            'client_email' => $this->client_email,
            'created_at' => $this->created_at->toIso8601String(),
            'selected_pictures' => $pictures->map(fn (Picture $p) => [
                'id' => $p->id,
                'filename' => $p->original_filename,
                'order_index' => $p->order_index,
            ])->toArray(),
        ];
    }

    /**
     * Export order as JSON string.
     */
    public function toExportJson(): string
    {
        return json_encode($this->toExportArray(), JSON_PRETTY_PRINT | JSON_UNESCAPED_SLASHES);
    }
}
