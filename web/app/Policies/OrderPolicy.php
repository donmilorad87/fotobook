<?php

namespace App\Policies;

use App\Models\Order;
use App\Models\User;

class OrderPolicy
{
    /**
     * Determine if the user can view the order.
     * User must own the gallery that the order belongs to.
     */
    public function view(User $user, Order $order): bool
    {
        return $user->id === $order->gallery->user_id;
    }

    /**
     * Determine if the user can delete the order.
     */
    public function delete(User $user, Order $order): bool
    {
        return $user->id === $order->gallery->user_id;
    }
}
