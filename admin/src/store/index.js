import Vue from 'vue'
import Vuex from 'vuex'

Vue.use(Vuex)

export default new Vuex.Store({
  state: {
    users: [],
    user: null,
    loading: false,
    error: null
  },
  getters: {
    users: state => state.users,
    user: state => state.user,
    loading: state => state.loading,
    error: state => state.error
  },
  mutations: {
    SET_USERS(state, users) {
      state.users = users
    },
    SET_USER(state, user) {
      state.user = user
    },
    SET_LOADING(state, loading) {
      state.loading = loading
    },
    SET_ERROR(state, error) {
      state.error = error
    }
  },
  actions: {
    async fetchUsers({ commit }) {
      commit('SET_LOADING', true)
      try {
        const response = await fetch('/api/users')
        const data = await response.json()
        commit('SET_USERS', data)
      } catch (error) {
        commit('SET_ERROR', error.message)
      } finally {
        commit('SET_LOADING', false)
      }
    }
  },
  modules: {
  }
})
