/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

(function (Mozilla) {
    'use strict';

    function handleOpenProtectionReport(e) {
        e.preventDefault();
        Mozilla.UITour.showProtectionReport();

        window.dataLayer.push({
            'event': 'in-page-interaction',
            'eAction': 'link click',
            'eLabel': 'View your protection report'
        });
    }

    function handleOpenProtectionReportLink(e) {
        e.preventDefault();
        Mozilla.UITour.showProtectionReport();

        window.dataLayer.push({
            'event': 'in-page-interaction',
            'eAction': 'link click',
            'eLabel': 'See what`s blocked'
        });
    }

    Mozilla.UITour.ping(function() {
        document.querySelectorAll('.protection-report.primary-cta').forEach(
            function(button) {
                button.addEventListener('click', handleOpenProtectionReport, false);
            }
        );
        document.querySelectorAll('.protection-report:not(.primary-cta)').forEach(
            function(button) {
                button.addEventListener('click', handleOpenProtectionReportLink, false);
            }
        );
    });

})(window.Mozilla);
