/**
 * ScanSmart Interactive Analytics & Chart.js Visualizations
 */

document.addEventListener('DOMContentLoaded', function () {
  // 1. Products by Category Chart (Doughnut)
  const catCanvas = document.getElementById('chartProductsByCategory');
  if (catCanvas && window.categoryChartData) {
    new Chart(catCanvas, {
      type: 'doughnut',
      data: {
        labels: window.categoryChartData.labels,
        datasets: [{
          data: window.categoryChartData.counts,
          backgroundColor: window.categoryChartData.colors || [
            '#10B981', '#3B82F6', '#F59E0B', '#EF4444',
            '#8B5CF6', '#EC4899', '#06B6D4', '#64748B',
            '#14B8A6', '#F43F5E', '#D97706', '#6B7280'
          ],
          borderWidth: 2,
          borderColor: '#FFFFFF',
        }]
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        plugins: {
          legend: {
            position: 'bottom',
            labels: { boxWidth: 12, font: { family: 'Plus Jakarta Sans', size: 11 } }
          }
        },
        cutout: '68%'
      }
    });
  }

  // 2. Monthly Scans Trend Chart (Line)
  const scansCanvas = document.getElementById('chartMonthlyScans');
  if (scansCanvas && window.scansChartData) {
    new Chart(scansCanvas, {
      type: 'line',
      data: {
        labels: window.scansChartData.labels,
        datasets: [{
          label: 'Total Scans',
          data: window.scansChartData.counts,
          borderColor: '#10B981',
          backgroundColor: 'rgba(16, 185, 129, 0.1)',
          fill: true,
          tension: 0.35,
          pointRadius: 4,
          pointBackgroundColor: '#10B981',
        }]
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        plugins: {
          legend: { display: false }
        },
        scales: {
          y: { beginAtZero: true, grid: { color: '#F1F5F9' } },
          x: { grid: { display: false } }
        }
      }
    });
  }

  // 3. Expiration Distribution Chart (Doughnut / Pie)
  const expiryCanvas = document.getElementById('chartExpiryDistribution');
  if (expiryCanvas && window.expiryChartData) {
    new Chart(expiryCanvas, {
      type: 'pie',
      data: {
        labels: ['Safe', 'Expiring Soon (<=7d)', 'Expired', 'No Expiry'],
        datasets: [{
          data: [
            window.expiryChartData.safe || 0,
            window.expiryChartData.expiringSoon || 0,
            window.expiryChartData.expired || 0,
            window.expiryChartData.noExpiry || 0
          ],
          backgroundColor: ['#10B981', '#F59E0B', '#EF4444', '#94A3B8'],
          borderWidth: 2,
          borderColor: '#FFFFFF',
        }]
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        plugins: {
          legend: {
            position: 'bottom',
            labels: { boxWidth: 12, font: { family: 'Plus Jakarta Sans', size: 11 } }
          }
        }
      }
    });
  }
});
