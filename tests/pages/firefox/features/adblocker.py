# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.

from selenium.webdriver.common.by import By

from pages.base import BasePage
from pages.regions.download_button import DownloadButton


class FeatureAdblockerPage(BasePage):
    _URL_TEMPLATE = "/{locale}/firefox/features/adblocker/"

    _download_button_locator = (By.ID, "download-button-desktop-release")

    @property
    def download_button(self):
        el = self.find_element(*self._download_button_locator)
        return DownloadButton(self, root=el)
