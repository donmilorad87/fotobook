<?php

namespace App\Policies;

use App\Models\Gallery;
use App\Models\User;

class GalleryPolicy
{
    /**
     * Determine if the user can view the gallery.
     */
    public function view(User $user, Gallery $gallery): bool
    {
        return $user->id === $gallery->user_id;
    }

    /**
     * Determine if the user can update the gallery.
     */
    public function update(User $user, Gallery $gallery): bool
    {
        return $user->id === $gallery->user_id;
    }

    /**
     * Determine if the user can delete the gallery.
     */
    public function delete(User $user, Gallery $gallery): bool
    {
        return $user->id === $gallery->user_id;
    }
}
