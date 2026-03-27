import { WagmiProvider } from 'wagmi'
import { QueryClient, QueryClientProvider } from '@tanstack/react-query'
import { RainbowKitProvider, darkTheme } from '@rainbow-me/rainbowkit'
import '@rainbow-me/rainbowkit/styles.css'
import { config } from './config/wagmi'
import { Header } from './components/Header'
import { SaleInfo } from './components/SaleInfo'
import { CvtBalance } from './components/CvtBalance'
import { BuyForm } from './components/BuyForm'

const queryClient = new QueryClient()

function App() {
  return (
    <WagmiProvider config={config}>
      <QueryClientProvider client={queryClient}>
        <RainbowKitProvider theme={darkTheme()}>
          <div className="relative min-h-screen text-white overflow-hidden"
            style={{ background: 'linear-gradient(135deg, #0d0119 0%, #1a0533 40%, #051f14 80%, #041a10 100%)' }}>
            {/* ETH logo watermark */}
            <svg
              viewBox="0 0 784 1277"
              xmlns="http://www.w3.org/2000/svg"
              className="pointer-events-none fixed"
              style={{
                width: '520px',
                opacity: 0.04,
                right: '-80px',
                top: '50%',
                transform: 'translateY(-50%)',
                zIndex: 0,
              }}
            >
              <polygon points="392,0 0,638 392,850 784,638" fill="white" />
              <polygon points="392,926 0,714 392,1277 784,714" fill="white" />
            </svg>
            <div className="relative z-10 max-w-2xl mx-auto px-4 py-8">
              <Header />
              <SaleInfo />
              <CvtBalance />
              <BuyForm />
            </div>
          </div>
        </RainbowKitProvider>
      </QueryClientProvider>
    </WagmiProvider>
  )
}

export default App
