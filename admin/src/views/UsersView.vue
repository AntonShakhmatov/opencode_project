<template>
  <div class="users">
    <h1>Users</h1>
    <div v-if="loading">Loading...</div>
    <div v-else-if="error">Error: {{ error }}</div>
    <ul v-else>
      <li v-for="user in users" :key="user.id">
        {{ user.name }} ({{ user.email }})
      </li>
    </ul>
  </div>
</template>

<script>
import { mapGetters } from 'vuex'

export default {
  name: 'UsersView',
  computed: {
    ...mapGetters(['users', 'loading', 'error'])
  },
  created() {
    this.$store.dispatch('fetchUsers')
  }
}
</script>
