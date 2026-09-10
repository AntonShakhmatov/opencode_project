import Vue from 'vue'
import Vuex from 'vuex'
import axios from 'axios'

Vue.use(Vuex)

const TOKEN_KEY = 'handyman_admin_token'
const USER_KEY = 'handyman_admin_user'

const api = axios.create({
  baseURL: '/api',
  timeout: 10000,
  headers: {
    'Content-Type': 'application/json'
  }
})

api.interceptors.request.use(config => {
  const token = localStorage.getItem(TOKEN_KEY)
  if (token) {
    config.headers.Authorization = `Bearer ${token}`
  }
  return config
})

api.interceptors.response.use(
  response => response,
  error => {
    if (error.response && error.response.status === 401) {
      localStorage.removeItem(TOKEN_KEY)
      localStorage.removeItem(USER_KEY)
      if (window.location.pathname !== '/login') {
        window.location.href = '/login'
      }
    }
    console.error('API Error:', error)
    return Promise.reject(error)
  }
)

export default new Vuex.Store({
  state: {
    token: localStorage.getItem(TOKEN_KEY) || null,
    currentUser: JSON.parse(localStorage.getItem(USER_KEY) || 'null'),
    users: [],
    jobs: [],
    reviews: [],
    stats: {
      totalUsers: 0,
      totalHandymen: 0,
      totalClients: 0,
      totalJobs: 0,
      activeJobs: 0,
      completedJobs: 0,
      totalReviews: 0,
    },
    loading: false,
    error: null
  },
  getters: {
    isAuthenticated: state => Boolean(state.token),
    currentUser: state => state.currentUser,
    users: state => state.users,
    jobs: state => state.jobs,
    reviews: state => state.reviews,
    stats: state => state.stats,
    loading: state => state.loading,
    error: state => state.error,
    activeJobs: state => state.jobs.filter(j => !['completed', 'cancelled'].includes(j.status)),
  },
  mutations: {
    SET_AUTH(state, { token, user }) {
      state.token = token
      state.currentUser = user || null
      localStorage.setItem(TOKEN_KEY, token)
      localStorage.setItem(USER_KEY, JSON.stringify(user || null))
    },
    CLEAR_AUTH(state) {
      state.token = null
      state.currentUser = null
      localStorage.removeItem(TOKEN_KEY)
      localStorage.removeItem(USER_KEY)
    },
    SET_JOBS(state, jobs) {
      state.jobs = jobs
      state.stats.totalJobs = jobs.length
      state.stats.activeJobs = jobs.filter(j => !['completed', 'cancelled'].includes(j.status)).length
      state.stats.completedJobs = jobs.filter(j => j.status === 'completed').length
    },
    SET_REVIEWS(state, reviews) {
      state.reviews = reviews
      state.stats.totalReviews = reviews.length
    },
    SET_STATS(state, stats) {
      state.stats = { ...state.stats, ...stats }
    },
    SET_LOADING(state, loading) {
      state.loading = loading
    },
    SET_ERROR(state, error) {
      state.error = error
    }
  },
  actions: {
    async fetchStats({ commit }) {
      try {
        const response = await api.get('/admin/stats')
        commit('SET_STATS', response.data)
      } catch (error) {
        console.error('Failed to fetch stats:', error)
      }
    },
    async fetchUsers({ commit }) {
      commit('SET_LOADING', true)
      try {
        const response = await api.get('/users')
        commit('SET_USERS', response.data)
      } catch (error) {
        commit('SET_ERROR', error.message)
      } finally {
        commit('SET_LOADING', false)
      }
    },
    async fetchJobs({ commit }) {
      commit('SET_LOADING', true)
      try {
        const response = await api.get('/jobs')
        commit('SET_JOBS', response.data)
      } catch (error) {
        commit('SET_ERROR', error.message)
      } finally {
        commit('SET_LOADING', false)
      }
    },
    async fetchReviews({ commit }) {
      commit('SET_LOADING', true)
      try {
        const response = await api.get('/reviews')
        commit('SET_REVIEWS', response.data)
      } catch (error) {
        commit('SET_ERROR', error.message)
      } finally {
        commit('SET_LOADING', false)
      }
    },
    async updateUser({ commit, dispatch }, { id, data }) {
      try {
        await api.put(`/users/${id}`, data)
        await dispatch('fetchUsers')
      } catch (error) {
        commit('SET_ERROR', error.message)
      }
    },
    async updateJob({ commit, dispatch }, { id, data }) {
      try {
        await api.put(`/jobs/${id}`, data)
        await dispatch('fetchJobs')
      } catch (error) {
        commit('SET_ERROR', error.message)
      }
    },
    async login({ commit, dispatch }, { email, password }) {
      commit('SET_LOADING', true)
      try {
        const response = await api.post('/auth/login', { email, password })
        const { accessToken, user } = response.data
        if (user.role !== 'admin') {
          throw new Error('Only admin users can access this dashboard')
        }
        commit('SET_AUTH', { token: accessToken, user })
        await dispatch('fetchStats')
        await dispatch('fetchUsers')
        await dispatch('fetchJobs')
        await dispatch('fetchReviews')
      } catch (error) {
        commit('SET_ERROR', error.response?.data?.message || error.message)
        throw error
      } finally {
        commit('SET_LOADING', false)
      }
    },
    async logout({ commit }) {
      commit('CLEAR_AUTH')
    },
  },
  modules: {
  }
})
