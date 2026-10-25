// import { useState } from 'react'
// import reactLogo from './assets/react.svg'
// import viteLogo from './assets/vite.svg'
// import cloudflareLogo from './assets/cloudflare.svg'
// import heroImg from './assets/hero.png'
import './App.css'
import Game from './Game'

import "@mantine/core/styles.css";

import { AppShell, MantineProvider } from "@mantine/core";

function App() {

  return (
    <MantineProvider>
      <AppShell>
        <AppShell.Header>
          
        </AppShell.Header>
        <AppShell.Main>
          <Game />
        </AppShell.Main>
      </AppShell>
    </MantineProvider>
  );
}

export default App
