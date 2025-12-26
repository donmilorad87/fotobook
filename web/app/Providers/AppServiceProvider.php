<?php

namespace App\Providers;

use App\Models\Gallery;
use App\Models\Order;
use App\Policies\GalleryPolicy;
use App\Policies\OrderPolicy;
use Illuminate\Support\Facades\Blade;
use Illuminate\Support\Facades\Gate;
use Illuminate\Support\ServiceProvider;

class AppServiceProvider extends ServiceProvider
{
    /**
     * Register any application services.
     */
    public function register(): void
    {
        //
    }

    /**
     * Bootstrap any application services.
     */
    public function boot(): void
    {
        // Register policies
        Gate::policy(Gallery::class, GalleryPolicy::class);
        Gate::policy(Order::class, OrderPolicy::class);

        // Register assets version helper
        Blade::directive('assetsVersion', function () {
            return "<?php echo config('app.assets_version'); ?>";
        });

        // Versioned URL - appends ?v=VERSION to any URL
        Blade::directive('versionedUrl', function ($expression) {
            return "<?php echo e({$expression}) . '?v=' . config('app.assets_version'); ?>";
        });

        // Versioned stylesheet - outputs <link> tag with version query string
        Blade::directive('versionedStylesheet', function ($expression) {
            return "<?php echo '<link rel=\"stylesheet\" href=\"' . e({$expression}) . '?v=' . config('app.assets_version') . '\">'; ?>";
        });

        // Versioned script - outputs <script> tag with version query string
        Blade::directive('versionedScript', function ($expression) {
            return "<?php echo '<script src=\"' . e({$expression}) . '?v=' . config('app.assets_version') . '\"></script>'; ?>";
        });

        // Versioned async script - outputs <script async> tag with version query string
        Blade::directive('versionedScriptAsync', function ($expression) {
            return "<?php echo '<script async src=\"' . e({$expression}) . '?v=' . config('app.assets_version') . '\"></script>'; ?>";
        });

        // Versioned defer script - outputs <script defer> tag with version query string
        Blade::directive('versionedScriptDefer', function ($expression) {
            return "<?php echo '<script defer src=\"' . e({$expression}) . '?v=' . config('app.assets_version') . '\"></script>'; ?>";
        });
    }
}
