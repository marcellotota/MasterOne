//
//  searchFilter.js
//  MasterOne
//
//  Created by Tota Marcello on 29/10/25.
//

document.addEventListener("DOMContentLoaded", () => {
    const searchInput = document.getElementById("searchInput");
    const tableRows = document.querySelectorAll("table tbody tr");

    searchInput.addEventListener("input", () => {
        const filter = searchInput.value.toLowerCase();

        tableRows.forEach(row => {
            const text = row.textContent.toLowerCase();
            row.style.display = text.includes(filter) ? "" : "none";
        });
    });
});
