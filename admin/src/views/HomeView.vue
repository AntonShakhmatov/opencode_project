<template>
  <div class="home">
    <h1>Handyman Admin Dashboard</h1>
    
    <div class="stats-grid">
      <div class="stat-card">
        <div class="stat-icon users">
          <i class="fas fa-users"></i>
        </div>
        <div class="stat-info">
          <h3>{{ stats.totalUsers }}</h3>
          <p>Total Users</p>
        </div>
      </div>
      
      <div class="stat-card">
        <div class="stat-icon handymen">
          <i class="fas fa-tools"></i>
        </div>
        <div class="stat-info">
          <h3>{{ stats.totalHandymen }}</h3>
          <p>Handymen</p>
        </div>
      </div>
      
      <div class="stat-card">
        <div class="stat-icon jobs">
          <i class="fas fa-briefcase"></i>
        </div>
        <div class="stat-info">
          <h3>{{ stats.totalJobs }}</h3>
          <p>Total Jobs</p>
        </div>
      </div>
      
      <div class="stat-card">
        <div class="stat-icon active">
          <i class="fas fa-clock"></i>
        </div>
        <div class="stat-info">
          <h3>{{ stats.activeJobs }}</h3>
          <p>Active Jobs</p>
        </div>
      </div>
    </div>
    
    <div class="recent-section">
      <h2>Recent Jobs</h2>
      <div v-if="loading">Loading...</div>
      <div v-else-if="error">Error: {{ error }}</div>
      <table v-else class="data-table">
        <thead>
          <tr>
            <th>ID</th>
            <th>Service</th>
            <th>Status</th>
            <th>Client</th>
            <th>Handyman</th>
            <th>Created</th>
          </tr>
        </thead>
        <tbody>
          <tr v-for="job in jobs.slice(0, 5)" :key="job.id">
            <td>{{ job.id.substring(0, 8) }}...</td>
            <td>{{ job.serviceType }}</td>
            <td>
              <span :class="'status-badge ' + job.status">
                {{ job.status }}
              </span>
            </td>
            <td>{{ job.client?.name || 'N/A' }}</td>
            <td>{{ job.handyman?.name || 'Unassigned' }}</td>
            <td>{{ formatDate(job.createdAt) }}</td>
          </tr>
        </tbody>
      </table>
    </div>
  </div>
</template>

<script>
import { mapGetters } from 'vuex'

export default {
  name: 'HomeView',
  computed: {
    ...mapGetters(['stats', 'jobs', 'loading', 'error'])
  },
  created() {
    this.$store.dispatch('fetchUsers')
    this.$store.dispatch('fetchJobs')
  },
  methods: {
    formatDate(date) {
      return new Date(date).toLocaleDateString()
    }
  }
}
</script>

<style scoped>
.stats-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
  gap: 20px;
  margin-bottom: 30px;
}

.stat-card {
  background: white;
  border-radius: 8px;
  padding: 20px;
  display: flex;
  align-items: center;
  box-shadow: 0 2px 4px rgba(0,0,0,0.1);
}

.stat-icon {
  width: 50px;
  height: 50px;
  border-radius: 8px;
  display: flex;
  align-items: center;
  justify-content: center;
  margin-right: 15px;
  font-size: 24px;
  color: white;
}

.stat-icon.users { background: #3498db; }
.stat-icon.handymen { background: #2ecc71; }
.stat-icon.jobs { background: #9b59b6; }
.stat-icon.active { background: #f39c12; }

.stat-info h3 {
  margin: 0;
  font-size: 24px;
}

.stat-info p {
  margin: 5px 0 0;
  color: #666;
}

.recent-section {
  background: white;
  border-radius: 8px;
  padding: 20px;
  box-shadow: 0 2px 4px rgba(0,0,0,0.1);
}

.data-table {
  width: 100%;
  border-collapse: collapse;
}

.data-table th,
.data-table td {
  padding: 12px;
  text-align: left;
  border-bottom: 1px solid #eee;
}

.data-table th {
  background: #f5f5f5;
  font-weight: 600;
}

.status-badge {
  padding: 4px 8px;
  border-radius: 4px;
  font-size: 12px;
  text-transform: uppercase;
}

.status-badge.pending { background: #fff3cd; color: #856404; }
.status-badge.searching { background: #cce5ff; color: #004085; }
.status-badge.matched { background: #e2d5f1; color: #563d7c; }
.status-badge.accepted { background: #d4edda; color: #155724; }
.status-badge.en_route { background: #d1ecf1; color: #0c5460; }
.status-badge.in_progress { background: #c3e6cb; color: #155724; }
.status-badge.completed { background: #d4edda; color: #155724; }
.status-badge.cancelled { background: #f8d7da; color: #721c24; }
</style>
