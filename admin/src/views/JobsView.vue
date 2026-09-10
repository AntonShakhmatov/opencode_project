<template>
  <div class="jobs">
    <h1>Job Management</h1>
    
    <div class="filters">
      <select v-model="statusFilter">
        <option value="">All Statuses</option>
        <option value="pending">Pending</option>
        <option value="searching">Searching</option>
        <option value="matched">Matched</option>
        <option value="accepted">Accepted</option>
        <option value="en_route">En Route</option>
        <option value="in_progress">In Progress</option>
        <option value="completed">Completed</option>
        <option value="cancelled">Cancelled</option>
      </select>
      <input v-model="searchQuery" placeholder="Search jobs..." />
    </div>
    
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
          <th>Price</th>
          <th>Created</th>
          <th>Actions</th>
        </tr>
      </thead>
      <tbody>
        <tr v-for="job in filteredJobs" :key="job.id">
          <td>{{ job.id.substring(0, 8) }}...</td>
          <td>{{ job.serviceType }}</td>
          <td>
            <span :class="'status-badge ' + job.status">
              {{ job.status }}
            </span>
          </td>
          <td>{{ job.client?.name || 'N/A' }}</td>
          <td>{{ job.handyman?.name || 'Unassigned' }}</td>
          <td>{{ job.finalPrice ? '$' + job.finalPrice : 'Pending' }}</td>
          <td>{{ formatDate(job.createdAt) }}</td>
          <td>
            <button @click="viewJob(job)" class="btn-view">View</button>
            <button 
              v-if="job.status === 'searching'" 
              @click="cancelJob(job)" 
              class="btn-cancel"
            >
              Cancel
            </button>
          </td>
        </tr>
      </tbody>
    </table>
    
    <div v-if="selectedJob" class="job-details">
      <h2>Job Details</h2>
      <div class="detail-grid">
        <div><strong>ID:</strong> {{ selectedJob.id }}</div>
        <div><strong>Service:</strong> {{ selectedJob.serviceType }}</div>
        <div><strong>Status:</strong> {{ selectedJob.status }}</div>
        <div><strong>Description:</strong> {{ selectedJob.description }}</div>
        <div><strong>Client:</strong> {{ selectedJob.client?.name }}</div>
        <div><strong>Handyman:</strong> {{ selectedJob.handyman?.name || 'Unassigned' }}</div>
        <div><strong>Address:</strong> {{ selectedJob.address || 'N/A' }}</div>
        <div><strong>Created:</strong> {{ formatDate(selectedJob.createdAt) }}</div>
      </div>
      <button @click="selectedJob = null" class="btn-close">Close</button>
    </div>
  </div>
</template>

<script>
import { mapGetters } from 'vuex'

export default {
  name: 'JobsView',
  data() {
    return {
      statusFilter: '',
      searchQuery: '',
      selectedJob: null
    }
  },
  computed: {
    ...mapGetters(['jobs', 'loading', 'error']),
    filteredJobs() {
      return this.jobs.filter(job => {
        const matchesStatus = !this.statusFilter || job.status === this.statusFilter
        const matchesSearch = !this.searchQuery || 
          job.serviceType.toLowerCase().includes(this.searchQuery.toLowerCase()) ||
          job.description.toLowerCase().includes(this.searchQuery.toLowerCase())
        return matchesStatus && matchesSearch
      })
    }
  },
  created() {
    this.$store.dispatch('fetchJobs')
  },
  methods: {
    formatDate(date) {
      return new Date(date).toLocaleDateString()
    },
    viewJob(job) {
      this.selectedJob = job
    },
    async cancelJob(job) {
      if (confirm('Are you sure you want to cancel this job?')) {
        await this.$store.dispatch('updateJob', {
          id: job.id,
          data: { status: 'cancelled' }
        })
      }
    }
  }
}
</script>

<style scoped>
.filters {
  display: flex;
  gap: 10px;
  margin-bottom: 20px;
}

.filters input,
.filters select {
  padding: 8px 12px;
  border: 1px solid #ddd;
  border-radius: 4px;
}

.data-table {
  width: 100%;
  border-collapse: collapse;
  background: white;
  border-radius: 8px;
  overflow: hidden;
  box-shadow: 0 2px 4px rgba(0,0,0,0.1);
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

.btn-view,
.btn-cancel {
  padding: 6px 12px;
  margin-right: 8px;
  border: none;
  border-radius: 4px;
  cursor: pointer;
}

.btn-view {
  background: #007bff;
  color: white;
}

.btn-cancel {
  background: #dc3545;
  color: white;
}

.job-details {
  position: fixed;
  top: 50%;
  left: 50%;
  transform: translate(-50%, -50%);
  background: white;
  padding: 24px;
  border-radius: 8px;
  box-shadow: 0 4px 20px rgba(0,0,0,0.3);
  z-index: 1000;
  min-width: 400px;
}

.detail-grid {
  display: grid;
  gap: 12px;
  margin: 16px 0;
}

.btn-close {
  padding: 8px 16px;
  background: #6c757d;
  color: white;
  border: none;
  border-radius: 4px;
  cursor: pointer;
}
</style>
