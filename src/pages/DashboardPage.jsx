import { StatCard, StatSkeleton } from '../components/StatCard'
import ChartSection from '../components/ChartSection'
import ActivityFeed from '../components/ActivityFeed'
import RecentTrips from '../components/RecentTrips'

function DashboardPage({ connectionStatus, statsCards, handleOpenDrivers, trips, rideRequests }) {
  return (
    <section className="dashboard">
      {/* Stats Grid */}
      <div className="stats-grid" id="stats-grid">
        {connectionStatus === 'loading'
          ? [1, 2, 3, 4].map(i => <StatSkeleton key={i} />)
          : statsCards.map(stat => (
            <StatCard
              key={stat.id}
              data={stat}
              onClick={stat.id === 'active-drivers' ? handleOpenDrivers : undefined}
            />
          ))
        }
      </div>

      {/* Chart + Activity */}
      <div className="content-grid">
        <ChartSection trips={trips} />
        <ActivityFeed rideRequests={rideRequests} />
      </div>

      {/* Recent Trips Table */}
      <RecentTrips trips={trips} />
    </section>
  )
}

export default DashboardPage
