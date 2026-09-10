<template>
  <div class="reviews">
    <h1>Reviews Management</h1>
    
    <div v-if="loading">Loading...</div>
    <div v-else-if="error">Error: {{ error }}</div>
    
    <div v-else class="reviews-grid">
      <div v-for="review in reviews" :key="review.id" class="review-card">
        <div class="review-header">
          <div class="rating">
            <span v-for="i in 5" :key="i" class="star" :class="{ filled: i <= review.rating }">
              ★
            </span>
          </div>
          <span class="date">{{ formatDate(review.createdAt) }}</span>
        </div>
        <div class="review-body">
          <p><strong>Reviewer:</strong> {{ review.reviewer?.name || 'Anonymous' }}</p>
          <p><strong>Reviewee:</strong> {{ review.reviewee?.name || 'Unknown' }}</p>
          <p v-if="review.comment" class="comment">"{{ review.comment }}"</p>
        </div>
      </div>
      
      <div v-if="reviews.length === 0" class="no-reviews">
        No reviews yet
      </div>
    </div>
  </div>
</template>

<script>
import { mapGetters } from 'vuex'

export default {
  name: 'ReviewsView',
  computed: {
    ...mapGetters(['reviews', 'loading', 'error'])
  },
  created() {
    this.$store.dispatch('fetchReviews')
  },
  methods: {
    formatDate(date) {
      return new Date(date).toLocaleDateString()
    }
  }
}
</script>

<style scoped>
.reviews-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(300px, 1fr));
  gap: 20px;
}

.review-card {
  background: white;
  border-radius: 8px;
  padding: 20px;
  box-shadow: 0 2px 4px rgba(0,0,0,0.1);
}

.review-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 12px;
}

.rating {
  font-size: 20px;
}

.star {
  color: #ddd;
}

.star.filled {
  color: #ffc107;
}

.date {
  color: #666;
  font-size: 14px;
}

.review-body p {
  margin: 8px 0;
}

.comment {
  font-style: italic;
  color: #555;
  border-left: 3px solid #ddd;
  padding-left: 12px;
}

.no-reviews {
  text-align: center;
  padding: 40px;
  color: #666;
  background: white;
  border-radius: 8px;
}
</style>
