import { useCallback, useEffect, useState } from 'react'
import './App.css'
import {
  countOnlineDrivers,
  countTrips,
  countUsers,
  getTotalRevenue,
  getUsers,
  onOnlineDrivers,
  onAllDrivers,
  onRecentRideRequests,
  onRecentTrips,
  onDriverLocations,
} from './firestoreService'

import Sidebar from './components/Sidebar'
import Header from './components/Header'
import ConnectionBanner from './components/ConnectionBanner'
import DriverModal from './components/DriverModal'

import DashboardPage from './pages/DashboardPage'
import RidesPage from './pages/RidesPage'
import DriversPage from './pages/DriversPage'
import CustomersPage from './pages/CustomersPage'
import AnalyticsPage from './pages/AnalyticsPage'
import MapPage from './pages/MapPage'
import PaymentsPage from './pages/PaymentsPage'
import SettingsPage from './pages/SettingsPage'
import ErrorBoundary from './components/ErrorBoundary'

import { formatNumber, formatCurrency } from './utils/helpers'

function App() {
  const [activeNav, setActiveNav] = useState('nav-dashboard')
  const [connectionStatus, setConnectionStatus] = useState('loading') // loading, connected, error
  const [connectionError, setConnectionError] = useState('')
  const [refreshing, setRefreshing] = useState(false)
  const [showDriverModal, setShowDriverModal] = useState(false)
  const [allDrivers, setAllDrivers] = useState(null)

  // Firebase data states
  const [stats, setStats] = useState({
    totalTrips: 0,
    onlineDrivers: 0,
    totalRevenue: 0,
    totalUsers: 0,
    totalDrivers: 0,
    totalCustomers: 0,
  })
  const [trips, setTrips] = useState([])
  const [rideRequests, setRideRequests] = useState([])
  const [onlineDriverCount, setOnlineDriverCount] = useState(0)
  const [onlineDriversList, setOnlineDriversList] = useState([])
  const [allDriversList, setAllDriversList] = useState([])
  const [driverLocations, setDriverLocations] = useState([])

  // Load stats from Firestore
  const loadStats = useCallback(async () => {
    try {
      const [totalTripsCount, onlineDrivers, revenue, totalUsers, totalDrivers, totalCustomers] =
        await Promise.all([
          countTrips(),
          countOnlineDrivers(),
          getTotalRevenue(),
          countUsers(),
          countUsers('driver'),
          countUsers('customer'),
        ])

      setStats({
        totalTrips: totalTripsCount,
        onlineDrivers,
        totalRevenue: revenue,
        totalUsers,
        totalDrivers,
        totalCustomers,
      })
      setOnlineDriverCount(onlineDrivers)
      setConnectionStatus('connected')
    } catch (error) {
      console.error('Error loading stats:', error)
      setConnectionStatus('error')
      setConnectionError(error.message)
    }
  }, [])

  // Refresh all data
  const handleRefresh = useCallback(async () => {
    setRefreshing(true)
    await loadStats()
    setTimeout(() => setRefreshing(false), 600)
  }, [loadStats])

  const handleOpenDrivers = useCallback(async () => {
    setShowDriverModal(true)
    try {
      const drivers = await getUsers('driver', 100)
      setAllDrivers(drivers)
    } catch (error) {
      console.error('Error loading drivers:', error)
      setAllDrivers([])
    }
  }, [])

  // Initial load + realtime listeners
  useEffect(() => {
    loadStats()

    const unsubTrips = onRecentTrips((newTrips) => {
      setTrips(newTrips)
    }, 20)

    const unsubRequests = onRecentRideRequests((newRequests) => {
      setRideRequests(newRequests)
    }, 20)

    const unsubDrivers = onOnlineDrivers((drivers) => {
      setOnlineDriverCount(drivers.length)
      setOnlineDriversList(drivers)
      setStats(prev => ({ ...prev, onlineDrivers: drivers.length }))
    })

    const unsubAllDrivers = onAllDrivers((drivers) => {
      setAllDriversList(drivers)
    })

    const unsubLocations = onDriverLocations((locations) => {
      setDriverLocations(locations)
    })

    return () => {
      unsubTrips()
      unsubRequests()
      unsubDrivers()
      unsubAllDrivers()
      unsubLocations()
    }
  }, [loadStats])

  // Build stats cards
  const statsCards = [
    {
      id: 'total-rides',
      label: 'Tổng chuyến đi',
      value: formatNumber(stats.totalTrips),
      subtitle: `${stats.totalDrivers} tài xế`,
      type: 'primary',
      icon: '🚗',
    },
    {
      id: 'active-drivers',
      label: 'Tài xế online',
      value: formatNumber(stats.onlineDrivers),
      subtitle: `/ ${stats.totalDrivers} tổng`,
      type: 'success',
      icon: '👨‍✈️',
    },
    {
      id: 'total-revenue',
      label: 'Doanh thu (VNĐ)',
      value: formatCurrency(stats.totalRevenue),
      subtitle: 'Hoàn thành',
      type: 'warning',
      icon: '💰',
    },
    {
      id: 'total-users',
      label: 'Người dùng',
      value: formatNumber(stats.totalUsers),
      subtitle: `${stats.totalCustomers} khách`,
      type: 'info',
      icon: '👥',
    },
  ]

  const renderContent = () => {
    switch (activeNav) {
      case 'nav-rides':
        return <RidesPage />
      case 'nav-drivers':
        return <DriversPage />
      case 'nav-customers':
        return <CustomersPage />
      case 'nav-analytics':
        return <AnalyticsPage stats={stats} trips={trips} />
      case 'nav-map':
        const mergedDrivers = allDriversList.map(driver => {
          const driverId = driver.id || driver.uid
          const loc = driverLocations.find(l => l.driverId === driverId || l.id === driverId)
          return loc ? { ...driver, ...loc } : driver
        })
        return (
          <ErrorBoundary>
            <MapPage drivers={mergedDrivers} trips={trips} />
          </ErrorBoundary>
        )
      case 'nav-payments':
        return <PaymentsPage trips={trips} />
      case 'nav-settings':
        return <SettingsPage />
      case 'nav-dashboard':
      default:
        return (
          <DashboardPage
            connectionStatus={connectionStatus}
            statsCards={statsCards}
            handleOpenDrivers={handleOpenDrivers}
            trips={trips}
            rideRequests={rideRequests}
          />
        )
    }
  }

  return (
    <div className="app">
      <Sidebar activeNav={activeNav} onNavClick={setActiveNav} onlineDriverCount={onlineDriverCount} />

      <main className="main">
        <ConnectionBanner status={connectionStatus} error={connectionError} />
        <Header isLive={connectionStatus === 'connected'} onRefresh={handleRefresh} loading={refreshing} />
        {renderContent()}
      </main>

      {showDriverModal && (
        <DriverModal
          drivers={allDrivers}
          onClose={() => { setShowDriverModal(false); setAllDrivers(null); }}
        />
      )}
    </div>
  )
}

export default App
