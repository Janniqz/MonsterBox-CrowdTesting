<script lang="ts">
    import { page } from "$app/stores"
</script>

<div id="error-container" class="flex flex-col w-screen h-screen">
    <div id="error-text-container" class="flex-row grid grid-cols-2 divide-x-4 mt-auto mx-auto mb-5">
        <div class="px-3 text-right text-7xl font-bold">Error</div>
        <div class="px-3 text-left text-2xl">
            <p>{$page.status}</p>
            <p>{$page.error.message}</p>
        </div>
    </div>
    <a class="w-36 h-8 border-2 rounded-3xl mb-auto mx-auto text-center leading-7 transition ease-in-out bg-transparent text-white hover:bg-white hover:text-black duration-300" href="/">
        Return
    </a>
</div>