<?php
/**
 * ScanSmart Admin Panel - Global Footer Component
 */

declare(strict_types=1);
?>
      </div><!-- /.admin-content -->

      <!-- Footer Bar -->
      <footer class="mt-auto px-4 py-3 bg-white border-top text-center text-muted" style="font-size: 12.5px;">
        <div class="d-flex flex-column flex-sm-row justify-content-between align-items-center gap-2 max-w-7xl mx-auto">
          <div>&copy; <?= date('Y') ?> <strong>ScanSmart</strong> — Universal Product Scanner & Smart Inventory. All rights reserved.</div>
          <div class="text-muted" style="font-size: 11px;">“Scan Anything. Know Everything. Never Miss an Expiry.”</div>
        </div>
      </footer>
    </main><!-- /.admin-main -->
  </div><!-- /.admin-wrapper -->

  <!-- Bootstrap 5.3 JavaScript Bundle -->
  <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/js/bootstrap.bundle.min.js"></script>

  <!-- Chart.js for real-time analytics -->
  <script src="https://cdn.jsdelivr.net/npm/chart.js@4.4.2/dist/chart.umd.min.js"></script>

  <!-- Custom Admin Scripts -->
  <script src="<?= base_url('assets/js/admin.js') ?>"></script>
  <?php if (!empty($extraJs)): ?>
    <?= $extraJs ?>
  <?php endif; ?>
</body>
</html>
