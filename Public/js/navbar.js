//
//  navbar.js
//  MasterOne
//
//  Created by Tota Marcello on 30/10/25.
//

document.addEventListener("DOMContentLoaded", () => {
    const toggle = document.getElementById("navbar-toggle");
    const menu = document.getElementById("navbar-menu");

    toggle.addEventListener("click", () => {
        menu.classList.toggle("open");
    });
});
