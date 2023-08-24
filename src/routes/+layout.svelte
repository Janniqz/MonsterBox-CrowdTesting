<script lang="ts">
    import { invalidate } from '$app/navigation';
    import { onMount } from 'svelte';
    import type { LayoutData } from './$types';
    import "../app.css";
    import { setSession } from '$components/userManagement/userStore';

    export let data: LayoutData;
    let { supabase, session } = data;
    $: ({ supabase, session } = data);

    onMount(() => {
        const {
            data: { subscription },
        } = supabase.auth.onAuthStateChange((event, _session) => {
            setSession(supabase, event, _session);
            if (_session?.expires_at !== session?.expires_at) {
                invalidate('supabase:auth');
            }
        });

        return () => subscription.unsubscribe();
    });
</script>

<svelte:head>
    <!-- META -->
    <title>MonsterBox</title>

    <!-- FAVICONS -->
    <link rel="apple-touch-icon" sizes="180x180" href="/imgs/favicons/apple-touch-icon.png">
    <link rel="icon" type="image/png" sizes="32x32" href="/imgs/favicons/favicon-32x32.png">
    <link rel="icon" type="image/png" sizes="16x16" href="/imgs/favicons/favicon-16x16.png">
    <link rel="shortcut icon" href="/imgs/favicons/favicon.ico">
    <link rel="manifest" href="/imgs/favicons/site.webmanifest">
    <link rel="mask-icon" href="/imgs/favicons/safari-pinned-tab.svg" color="#000000">
    <meta name="msapplication-TileColor" content="#000000">
    <meta name="msapplication-TileImage" content="/imgs/favicons/mstile-150x150.png">
    <meta name="msapplication-config" content="/imgs/favicons/browserconfig.xml">
    <meta name="theme-color" content="#ffffff">

    <!-- CSS -->
    <link href="/ext/fontawesome/css/fontawesome.css" rel="stylesheet">
    <link href="/ext/fontawesome/css/brands.css" rel="stylesheet">
    <link href="/ext/fontawesome/css/solid.css" rel="stylesheet">
</svelte:head>

<slot />