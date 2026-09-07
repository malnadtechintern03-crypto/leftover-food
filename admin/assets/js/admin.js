/**
 * Home Pantry Admin Panel - Client Script
 */

document.addEventListener('DOMContentLoaded', () => {
  // 1. Mobile Sidebar Toggle
  const sidebarToggle = document.getElementById('btnSidebarToggle');
  const sidebar = document.querySelector('.admin-sidebar');
  const backdrop = document.getElementById('sidebarBackdrop');

  if (sidebarToggle && sidebar && backdrop) {
    sidebarToggle.addEventListener('click', () => {
      sidebar.classList.toggle('show');
      backdrop.classList.toggle('show');
    });

    backdrop.addEventListener('click', () => {
      sidebar.classList.remove('show');
      backdrop.classList.remove('show');
    });
  }

  // 2. Client-side Live Table Filter
  const searchInput = document.getElementById('tableSearchInput');
  if (searchInput) {
    searchInput.addEventListener('input', (e) => {
      const term = e.target.value.toLowerCase().trim();
      const rows = document.querySelectorAll('.custom-table tbody tr');

      rows.forEach((row) => {
        const text = row.textContent.toLowerCase();
        row.style.display = text.includes(term) ? '' : 'none';
      });
    });
  }

  // 3. Dynamic Recipe Ingredient Row Adder
  const addIngredientBtn = document.getElementById('btnAddIngredientRow');
  const ingredientsContainer = document.getElementById('ingredientsContainer');

  if (addIngredientBtn && ingredientsContainer) {
    addIngredientBtn.addEventListener('click', () => {
      const index = ingredientsContainer.children.length;
      const row = document.createElement('div');
      row.className = 'row g-2 mb-2 align-items-center ingredient-row';
      row.innerHTML = `
        <div class="col-md-5">
          <input type="text" name="ingredients[${index}][name]" class="form-control" placeholder="Ingredient Name (e.g. Sourdough Bread)" required>
        </div>
        <div class="col-md-2">
          <input type="text" name="ingredients[${index}][quantity]" class="form-control" placeholder="Qty (e.g. 2)">
        </div>
        <div class="col-md-2">
          <input type="text" name="ingredients[${index}][unit]" class="form-control" placeholder="Unit (e.g. slices)">
        </div>
        <div class="col-md-2">
          <select name="ingredients[${index}][is_required]" class="form-select">
            <option value="1">Required</option>
            <option value="0">Optional</option>
          </select>
        </div>
        <div class="col-md-1 text-center">
          <button type="button" class="btn btn-sm btn-outline-danger btn-remove-row" title="Remove ingredient">
            <span class="material-symbols-rounded" style="font-size: 18px;">delete</span>
          </button>
        </div>
      `;
      ingredientsContainer.appendChild(row);

      row.querySelector('.btn-remove-row').addEventListener('click', () => {
        row.remove();
      });
    });

    // Attach to existing rows
    document.querySelectorAll('.btn-remove-row').forEach((btn) => {
      btn.addEventListener('click', (e) => {
        const row = e.target.closest('.ingredient-row');
        if (row) row.remove();
      });
    });
  }
});

/**
 * Universal deletion confirmation helper
 */
function confirmDelete(message = 'Are you sure you want to delete this item? This action cannot be undone.') {
  return window.confirm(message);
}
