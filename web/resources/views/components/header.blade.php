<header class="app-header">
    <div class="header-left">
        <button class="sidebar-toggle btn btn-secondary btn-sm" aria-label="Toggle sidebar">
            <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2" style="width: 20px; height: 20px;">
                <path stroke-linecap="round" stroke-linejoin="round" d="M4 6h16M4 12h16M4 18h16" />
            </svg>
        </button>
        <h1 class="header-title">@yield('page-title', 'Dashboard')</h1>
    </div>

    <div class="header-user">
        <span class="header-user-name">{{ Auth::user()->name }}</span>
        <div class="header-user-avatar">
            {{ Auth::user()->initials }}
        </div>
    </div>
</header>
