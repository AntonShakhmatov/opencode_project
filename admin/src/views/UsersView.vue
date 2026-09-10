<template>
  <div class="users">
    <h1>User Management</h1>
    
    <div class="filters">
      <select v-model="roleFilter">
        <option value="">All Roles</option>
        <option value="client">Clients</option>
        <option value="handyman">Handymen</option>
        <option value="admin">Admins</option>
      </select>
      <input v-model="searchQuery" placeholder="Search users..." />
    </div>
    
    <div v-if="loading">Loading...</div>
    <div v-else-if="error">Error: {{ error }}</div>
    
    <table v-else class="data-table">
      <thead>
        <tr>
          <th>Name</th>
          <th>Email</th>
          <th>Role</th>
          <th>Rating</th>
          <th>Status</th>
          <th>Actions</th>
        </tr>
      </thead>
      <tbody>
        <tr v-for="user in filteredUsers" :key="user.id">
          <td>{{ user.name }}</td>
          <td>{{ user.email }}</td>
          <td>
            <span :class="'role-badge ' + user.role">
              {{ user.role }}
            </span>
          </td>
          <td>{{ user.rating ? user.rating.toFixed(1) : 'N/A' }}</td>
          <td>
            <span :class="user.isAvailable ? 'status-active' : 'status-inactive'">
              {{ user.isAvailable ? 'Available' : 'Unavailable' }}
            </span>
          </td>
          <td>
            <button @click="editUser(user)" class="btn-edit">Edit</button>
            <button @click="toggleAvailability(user)" class="btn-toggle">
              {{ user.isAvailable ? 'Deactivate' : 'Activate' }}
            </button>
          </td>
        </tr>
      </tbody>
    </table>
  </div>
</template>

<script>
import { mapGetters } from 'vuex'

export default {
  name: 'UsersView',
  data() {
    return {
      roleFilter: '',
      searchQuery: ''
    }
  },
  computed: {
    ...mapGetters(['users', 'loading', 'error']),
    filteredUsers() {
      return this.users.filter(user => {
        const matchesRole = !this.roleFilter || user.role === this.roleFilter
        const matchesSearch = !this.searchQuery || 
          user.name.toLowerCase().includes(this.searchQuery.toLowerCase()) ||
          user.email.toLowerCase().includes(this.searchQuery.toLowerCase())
        return matchesRole && matchesSearch
      })
    }
  },
  created() {
    this.$store.dispatch('fetchUsers')
  },
  methods: {
    editUser(user) {
      // TODO: Open edit modal
      console.log('Edit user:', user)
    },
    async toggleAvailability(user) {
      await this.$store.dispatch('updateUser', {
        id: user.id,
        data: { isAvailable: !user.isAvailable }
      })
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

.role-badge {
  padding: 4px 8px;
  border-radius: 4px;
  font-size: 12px;
  text-transform: uppercase;
}

.role-badge.client { background: #cce5ff; color: #004085; }
.role-badge.handyman { background: #d4edda; color: #155724; }
.role-badge.admin { background: #f8d7da; color: #721c24; }

.status-active { color: #28a745; }
.status-inactive { color: #dc3545; }

.btn-edit,
.btn-toggle {
  padding: 6px 12px;
  margin-right: 8px;
  border: none;
  border-radius: 4px;
  cursor: pointer;
}

.btn-edit {
  background: #007bff;
  color: white;
}

.btn-toggle {
  background: #6c757d;
  color: white;
}
</style>
