import { getDefaultConfig } from '@rainbow-me/rainbowkit'
import { hardhat } from 'wagmi/chains'

export const config = getDefaultConfig({
  appName: 'CryptoVision Token Sale',
  projectId: 'development',
  chains: [hardhat],
})
