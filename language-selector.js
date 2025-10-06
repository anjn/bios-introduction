// Language selector for BIOS Introduction book
// Switches between Japanese (ja) and English (en)

(function() {
    'use strict';

    const LANGUAGES = {
        'ja': { name: '日本語', flag: '🇯🇵' },
        'en': { name: 'English', flag: '🇬🇧' }
    };

    function getCurrentLanguage() {
        const path = window.location.pathname;
        // Check if path starts with /en/
        if (path.startsWith('/en/')) {
            return 'en';
        }
        // Default to Japanese
        return 'ja';
    }

    function getOtherLanguageUrl(currentLang) {
        const path = window.location.pathname;

        if (currentLang === 'ja') {
            // Switch to English: add /en/ prefix
            return '/en' + path;
        } else {
            // Switch to Japanese: remove /en/ prefix
            return path.replace(/^\/en/, '');
        }
    }

    function createLanguageSelector() {
        const currentLang = getCurrentLanguage();
        const otherLang = currentLang === 'ja' ? 'en' : 'ja';

        // Create container
        const container = document.createElement('div');
        container.id = 'language-selector';
        container.className = 'language-selector';

        // Create button
        const button = document.createElement('a');
        button.href = getOtherLanguageUrl(currentLang);
        button.className = 'language-toggle';
        button.innerHTML = `
            <span class="lang-flag">${LANGUAGES[otherLang].flag}</span>
            <span class="lang-name">${LANGUAGES[otherLang].name}</span>
        `;
        button.title = `Switch to ${LANGUAGES[otherLang].name}`;

        container.appendChild(button);

        // Insert into menu bar (after the title)
        const menuBar = document.querySelector('.menu-bar');
        if (menuBar) {
            const leftButtons = menuBar.querySelector('.left-buttons');
            if (leftButtons) {
                leftButtons.appendChild(container);
            } else {
                menuBar.insertBefore(container, menuBar.firstChild);
            }
        }
    }

    // Initialize when DOM is ready
    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', createLanguageSelector);
    } else {
        createLanguageSelector();
    }
})();
