<!DOCTYPE html>
<html lang="{{ str_replace('_', '-', app()->getLocale()) }}">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <meta name="csrf-token" content="{{ csrf_token() }}">
    <meta name="assets-version" content="@assetsVersion">

    <title>@yield('title', 'Dashboard') - {{ config('app.name') }}</title>

    @vite(['resources/css/app.scss', 'resources/js/app.js', 'resources/js/google-image-loader.js'])
    <script src="{{ asset('js/image-cache-service.js') }}?v={{ config('app.assets_version') }}"></script>
</head>
<body>
    <div class="app-layout">
        <div class="sidebar-overlay"></div>
        @include('components.sidebar')

        <div class="app-main">
            @include('components.header')

            <main class="app-content">
                @if (session('success'))
                    <div class="alert alert-success" data-auto-dismiss="5000">
                        {{ session('success') }}
                    </div>
                @endif

                @if (session('warning'))
                    <div class="alert alert-warning" data-auto-dismiss="5000">
                        {{ session('warning') }}
                    </div>
                @endif

                @if (session('error'))
                    <div class="alert alert-danger" data-auto-dismiss="5000">
                        {{ session('error') }}
                    </div>
                @endif

                @yield('content')
            </main>
        </div>
    </div>

    @if (session('invalidate_cache'))
    <script>
        document.addEventListener('DOMContentLoaded', function() {
            var imageIds = @json(session('invalidate_cache'));
            if (window.imageCacheService && imageIds && imageIds.length > 0) {
                window.imageCacheService.deleteMultiple(imageIds)
                    .then(function(count) {
                        console.log('Invalidated ' + count + ' cached images');
                    })
                    .catch(function(error) {
                        console.warn('Cache invalidation failed:', error);
                    });
            }
        });
    </script>
    @endif
</body>
</html>
