import { Routes, Route } from 'react-router-dom'
import Layout from './components/Layout'
import Dashboard from './pages/Dashboard'
import Projects from './pages/Projects'
import Models from './pages/Models'
import Prompts from './pages/Prompts'
import Requests from './pages/Requests'
import Evaluations from './pages/Evaluations'
import Datasets from './pages/Datasets'
import Workflows from './pages/Workflows'

function App() {
  return (
    <Routes>
      <Route path="/" element={<Layout />}>
        <Route index element={<Dashboard />} />
        <Route path="projects" element={<Projects />} />
        <Route path="models" element={<Models />} />
        <Route path="prompts" element={<Prompts />} />
        <Route path="requests" element={<Requests />} />
        <Route path="evaluations" element={<Evaluations />} />
        <Route path="datasets" element={<Datasets />} />
        <Route path="workflows" element={<Workflows />} />
      </Route>
    </Routes>
  )
}

export default App


