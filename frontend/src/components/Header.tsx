import { ConnectButton } from '@rainbow-me/rainbowkit'

export function Header() {
  return (
    <nav className="flex items-center justify-between px-6 py-4 mb-8 bg-white/5 backdrop-blur-xl border border-white/10 rounded-2xl">
      <div className="flex items-center gap-3">
        <div className="w-10 h-10 rounded-xl bg-gradient-to-br from-purple-500 to-cyan-400 flex items-center justify-center text-white font-bold text-lg">
          CV
        </div>
        <span className="text-xl font-bold text-white">CryptoVision</span>
      </div>
      <ConnectButton />
    </nav>
  )
}
