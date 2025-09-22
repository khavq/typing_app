export default {
  mounted() {
    this.initSoundSystem()
    this.lastSoundEvent = null
    this.soundEnabled = true
    this.typingSoundEnabled = true
    this.backgroundMusicEnabled = false
    this.backgroundMusicPlaying = false
    this.backgroundMusicAudio = null

    // Initialize music library for better UX when user enables music
    setTimeout(() => {
      this.initBackgroundMusic()
    }, 2000) // Delay by 2s to not interfere with initial page load
    
    // Listen for updates from LiveView
    this.handleEvent = (event, payload) => {
      // Handle any custom events if needed
    }
  },

  updated() {
    // Check for sound events when component updates
    const soundData = document.getElementById('sound-data')
    if (soundData) {
      const soundEnabled = soundData.dataset.soundEnabled === "true"
      const typingSoundEnabled = soundData.dataset.typingSoundEnabled === "true"
      const backgroundMusicEnabled = soundData.dataset.backgroundMusicEnabled === "true"
      const lastSoundEvent = soundData.dataset.lastSoundEvent
      const keyPressed = soundData.hasAttribute('data-key-pressed')
      const gameState = document.querySelector('.game-state')?.dataset?.state || ''

      this.soundEnabled = soundEnabled
      this.typingSoundEnabled = typingSoundEnabled
      const wasBackgroundMusicEnabled = this.backgroundMusicEnabled
      this.backgroundMusicEnabled = backgroundMusicEnabled

      // Handle background music toggling
      if (backgroundMusicEnabled !== wasBackgroundMusicEnabled) {
        if (backgroundMusicEnabled && soundEnabled) {
          this.startBackgroundMusic()
        } else {
          this.stopBackgroundMusic()
        }
      }

      // Start/stop background music based on game state
      const isPlaying = gameState === 'playing' || document.querySelector('.game-complete')
      if (this.backgroundMusicEnabled && soundEnabled && isPlaying && !this.backgroundMusicPlaying) {
        this.startBackgroundMusic()
      } else if ((!this.backgroundMusicEnabled || !soundEnabled || !isPlaying) && this.backgroundMusicPlaying) {
        this.stopBackgroundMusic()
      }

      // Track if we've played a keystroke sound to avoid duplicate sounds
      const currentIndex = parseInt(soundData.dataset.currentIndex || '0')
      if (this.lastIndex !== currentIndex) {
        this.lastIndex = currentIndex
        this.keyStrokePlayed = false
      }

      // Play keystroke sound when typing correctly
      if (keyPressed && this.typingSoundEnabled && this.soundEnabled && !this.keyStrokePlayed) {
        this.playKeySound()
        this.keyStrokePlayed = true
      }

      // Play other sound events
      if (lastSoundEvent && lastSoundEvent !== this.lastSoundEvent && this.soundEnabled) {
        console.log('Playing sound', lastSoundEvent)
        this.playSound(lastSoundEvent)
        this.lastSoundEvent = lastSoundEvent
      }
    }
  },

  initSoundSystem() {
    try {
      console.log('Web Audio API supported')
      this.audioContext = new (window.AudioContext || window.webkitAudioContext)()
    } catch (e) {
      console.log('Web Audio API not supported')
    }
  },

  resumeContext() {
    if (this.audioContext && this.audioContext.state === 'suspended') {
      this.audioContext.resume()
    }
  },

  initBackgroundMusic() {
    // Skip initialization if already done
    if (this.musicInitialized) return;
    
    // No external files needed - entirely Web Audio API based
    console.log('Initializing WebAudio music library...');
    
    // Create music library with different styles
    this.musicLibrary = [
      this.createAmbienceTrack,
      this.createLofiTrack,
      this.createPianoTrack,
      this.createMeditationTrack,
      this.createCalmTrack
    ];
    
    this.musicInitialized = true;
    console.log('Web Audio music library initialized with 5 tracks');
  },
  
  // Track 1: Ambient Atmosphere
  createAmbienceTrack() {
    if (!this.audioContext) return null;
    this.resumeContext();
    
    const master = this.audioContext.createGain();
    master.gain.value = 0.15;
    master.connect(this.audioContext.destination);
    
    // Create pad sounds
    const createPad = (baseFreq, detune) => {
      const osc = this.audioContext.createOscillator();
      const gain = this.audioContext.createGain();
      const filter = this.audioContext.createBiquadFilter();
      
      osc.type = 'sine';
      osc.frequency.value = baseFreq;
      osc.detune.value = detune;
      
      filter.type = 'lowpass';
      filter.frequency.value = 1000;
      filter.Q.value = 1.5;
      
      gain.gain.value = 0.1;
      
      osc.connect(filter);
      filter.connect(gain);
      gain.connect(master);
      
      osc.start();
      return { oscillator: osc, gain: gain, filter: filter };
    };
    
    // Create ambient pad chord (Fm9)
    const pads = [
      createPad(174.61, 0),     // F3
      createPad(349.23, 5),     // F4
      createPad(415.30, -5),    // Ab4
      createPad(523.25, 0),     // C5
      createPad(587.33, 4)      // D5
    ];
    
    // Add slow LFO for movement
    const lfo = this.audioContext.createOscillator();
    const lfoGain = this.audioContext.createGain();
    
    lfo.type = 'sine';
    lfo.frequency.value = 0.05;
    lfoGain.gain.value = 100;
    
    lfo.connect(lfoGain);
    pads.forEach(pad => lfoGain.connect(pad.filter.frequency));
    
    lfo.start();
    
    return {
      pads: pads,
      lfo: lfo,
      master: master,
      name: 'Ambient Atmosphere'
    };
  },
  
  // Track 2: Lofi Style
  createLofiTrack() {
    if (!this.audioContext) return null;
    this.resumeContext();
    
    const master = this.audioContext.createGain();
    master.gain.value = 0.25;
    master.connect(this.audioContext.destination);
    
    // Lofi chord progression using simple tones
    const createNote = (freq, time, duration, type = 'triangle') => {
      const osc = this.audioContext.createOscillator();
      const gain = this.audioContext.createGain();
      const filter = this.audioContext.createBiquadFilter();
      
      osc.type = type;
      osc.frequency.value = freq;
      
      filter.type = 'lowpass';
      filter.frequency.value = 1200;
      
      gain.gain.value = 0.0;
      gain.gain.setValueAtTime(0.0, this.audioContext.currentTime + time);
      gain.gain.linearRampToValueAtTime(0.1, this.audioContext.currentTime + time + 0.02);
      gain.gain.setValueAtTime(0.1, this.audioContext.currentTime + time + duration - 0.05);
      gain.gain.linearRampToValueAtTime(0.0, this.audioContext.currentTime + time + duration);
      
      osc.connect(filter);
      filter.connect(gain);
      gain.connect(master);
      
      osc.start();
      osc.stop(this.audioContext.currentTime + time + duration + 0.1);
      
      return { oscillator: osc, gain: gain };
    };
    
    // Lofi pattern
    const loopLength = 4; // 4 seconds per loop
    const scheduleLoop = () => {
      // Cmaj7 chord
      createNote(261.63, 0, 0.8);       // C4
      createNote(329.63, 0, 0.8);       // E4
      createNote(392.00, 0, 0.8);       // G4
      createNote(493.88, 0, 0.8);       // B4
      
      // Am7 chord
      createNote(220.00, 1, 0.8);       // A3
      createNote(261.63, 1, 0.8);       // C4
      createNote(329.63, 1, 0.8);       // E4
      createNote(392.00, 1, 0.8);       // G4
      
      // Fmaj7 chord
      createNote(174.61, 2, 0.8);       // F3
      createNote(220.00, 2, 0.8);       // A3
      createNote(261.63, 2, 0.8);       // C4
      createNote(349.23, 2, 0.8);       // F4
      
      // G7 chord
      createNote(196.00, 3, 0.8);       // G3
      createNote(246.94, 3, 0.8);       // B3
      createNote(293.66, 3, 0.8);       // D4
      createNote(349.23, 3, 0.8);       // F4
      
      // Schedule next loop
      this.loopTimer = setTimeout(scheduleLoop, loopLength * 1000);
    };
    
    // Start the loop
    scheduleLoop();
    
    return {
      master: master,
      stopLoop: () => {
        if (this.loopTimer) {
          clearTimeout(this.loopTimer);
          this.loopTimer = null;
        }
      },
      name: 'Lofi Beats'
    };
  },
  
  // Track 3: Piano Meditation
  createPianoTrack() {
    if (!this.audioContext) return null;
    this.resumeContext();
    
    const master = this.audioContext.createGain();
    master.gain.value = 0.2;
    master.connect(this.audioContext.destination);
    
    // Piano-like sound
    const createPianoNote = (freq, startTime, length) => {
      const osc = this.audioContext.createOscillator();
      const gain = this.audioContext.createGain();
      
      osc.type = 'sine';
      osc.frequency.value = freq;
      
      // Piano-like envelope
      gain.gain.setValueAtTime(0, this.audioContext.currentTime + startTime);
      gain.gain.linearRampToValueAtTime(0.2, this.audioContext.currentTime + startTime + 0.02);
      gain.gain.exponentialRampToValueAtTime(0.01, this.audioContext.currentTime + startTime + length);
      
      osc.connect(gain);
      gain.connect(master);
      
      osc.start(this.audioContext.currentTime + startTime);
      osc.stop(this.audioContext.currentTime + startTime + length + 0.1);
      
      return { oscillator: osc, gain: gain };
    };
    
    // Gentle piano arpeggio in A minor
    const playArpeggio = () => {
      createPianoNote(220.00, 0.0, 1.5);  // A3
      createPianoNote(261.63, 0.5, 1.5);  // C4
      createPianoNote(329.63, 1.0, 1.5);  // E4
      createPianoNote(440.00, 1.5, 1.5);  // A4
      createPianoNote(523.25, 2.0, 1.5);  // C5
      createPianoNote(659.26, 2.5, 1.5);  // E5
      createPianoNote(440.00, 3.0, 1.5);  // A4
      createPianoNote(329.63, 3.5, 1.5);  // E4
      
      // Schedule next arpeggio
      this.pianoTimer = setTimeout(playArpeggio, 4000);
    };
    
    // Start the piano sequence
    playArpeggio();
    
    return {
      master: master,
      stopPiano: () => {
        if (this.pianoTimer) {
          clearTimeout(this.pianoTimer);
          this.pianoTimer = null;
        }
      },
      name: 'Piano Meditation'
    };
  },
  
  // Track 4: Deep Meditation
  createMeditationTrack() {
    if (!this.audioContext) return null;
    this.resumeContext();
    
    const master = this.audioContext.createGain();
    master.gain.value = 0.15;
    master.connect(this.audioContext.destination);
    
    // Drone synths
    const createDrone = (freq, type = 'sine') => {
      const osc = this.audioContext.createOscillator();
      const gain = this.audioContext.createGain();
      const filter = this.audioContext.createBiquadFilter();
      
      osc.type = type;
      osc.frequency.value = freq;
      
      filter.type = 'lowpass';
      filter.frequency.value = 800;
      
      gain.gain.value = 0.1;
      
      osc.connect(filter);
      filter.connect(gain);
      gain.connect(master);
      
      osc.start();
      
      return { oscillator: osc, gain: gain, filter: filter };
    };
    
    // Create drones in perfect fifths for meditation
    const drones = [
      createDrone(110),    // A2
      createDrone(164.81), // E3
      createDrone(220),    // A3
      createDrone(293.66)  // D4
    ];
    
    // Add very slow LFO for subtle movement
    const lfo = this.audioContext.createOscillator();
    const lfoGain = this.audioContext.createGain();
    
    lfo.type = 'triangle';
    lfo.frequency.value = 0.03;
    lfoGain.gain.value = 100;
    
    lfo.connect(lfoGain);
    drones.forEach(drone => {
      lfoGain.connect(drone.filter.frequency);
    });
    
    lfo.start();
    
    return {
      drones: drones,
      lfo: lfo,
      master: master,
      name: 'Deep Meditation'
    };
  },
  
  // Track 5: Calm Vibes
  createCalmTrack() {
    if (!this.audioContext) return null;
    this.resumeContext();
    
    const master = this.audioContext.createGain();
    master.gain.value = 0.15;
    master.connect(this.audioContext.destination);
    
    // Mellow synth pad
    const createMellowPad = (frequency, detune = 0) => {
      const oscillator1 = this.audioContext.createOscillator();
      const oscillator2 = this.audioContext.createOscillator();
      const gainNode = this.audioContext.createGain();
      const filter = this.audioContext.createBiquadFilter();
      
      oscillator1.type = 'sine';
      oscillator1.frequency.value = frequency;
      oscillator1.detune.value = detune;
      
      oscillator2.type = 'triangle';
      oscillator2.frequency.value = frequency * 2;
      oscillator2.detune.value = detune - 5;
      
      filter.type = 'lowpass';
      filter.frequency.value = 1000;
      filter.Q.value = 0.8;
      
      gainNode.gain.value = 0.08;
      
      oscillator1.connect(filter);
      oscillator2.connect(filter);
      filter.connect(gainNode);
      gainNode.connect(master);
      
      oscillator1.start();
      oscillator2.start();
      
      return { oscillators: [oscillator1, oscillator2], gain: gainNode, filter: filter };
    };
    
    // Create Gmaj9 chord (G, B, D, F#, A)
    const pads = [
      createMellowPad(196.00, 0),   // G3
      createMellowPad(246.94, 4),   // B3
      createMellowPad(293.66, -4),  // D4
      createMellowPad(370.00, 0),   // F#4
      createMellowPad(440.00, 3)    // A4
    ];
    
    return {
      pads: pads,
      master: master,
      name: 'Calm Vibes'
    };
  },
  
  startBackgroundMusic() {
    if (!this.soundEnabled || !this.backgroundMusicEnabled || this.backgroundMusicPlaying) return;

    // Initialize music library if not already done
    if (!this.musicInitialized) {
      this.initBackgroundMusic();
    }
    
    try {
      // Make sure Web Audio API is available
      if (!this.audioContext) {
        console.error('Web Audio API not available');
        return;
      }

      // Select a random track from our library
      const trackIndex = Math.floor(Math.random() * this.musicLibrary.length);
      const createTrackFunction = this.musicLibrary[trackIndex];
      
      // Create the selected track
      this.currentMusicTrack = createTrackFunction.call(this);
      
      if (this.currentMusicTrack) {
        console.log(`Playing background music: ${this.currentMusicTrack.name}`);
        this.backgroundMusicPlaying = true;
      } else {
        console.error('Failed to create music track');
      }
      
    } catch (error) {
      console.error('Error starting background music:', error);
      this.tryFallbackAudio(); // Use the simplest fallback as a last resort
    }
  },

  stopBackgroundMusic() {
    this.backgroundMusicPlaying = false;
    
    // Stop the current music track if it exists
    if (this.currentMusicTrack) {
      try {
        // Handle different types of tracks
        
        // Stop Lofi track (needs to clear timeout)
        if (this.currentMusicTrack.stopLoop) {
          this.currentMusicTrack.stopLoop();
        }
        
        // Stop Piano track (needs to clear timeout)
        if (this.currentMusicTrack.stopPiano) {
          this.currentMusicTrack.stopPiano();
        }
        
        // Stop oscillators in ambient/pad tracks
        if (this.currentMusicTrack.pads) {
          this.currentMusicTrack.pads.forEach(pad => {
            if (pad.oscillator) {
              pad.oscillator.stop();
            }
            if (pad.oscillators) {
              pad.oscillators.forEach(osc => osc.stop());
            }
          });
        }
        
        // Stop drones in meditation track
        if (this.currentMusicTrack.drones) {
          this.currentMusicTrack.drones.forEach(drone => {
            drone.oscillator.stop();
          });
        }
        
        // Stop LFO if it exists
        if (this.currentMusicTrack.lfo) {
          this.currentMusicTrack.lfo.stop();
        }
        
        console.log(`Stopped ${this.currentMusicTrack.name} music`);
        this.currentMusicTrack = null;
      } catch (e) {
        console.error('Error stopping background music:', e);
      }
    }

    // Stop fallback oscillators if they exist
    if (this.fallbackOscillators) {
      try {
        if (this.fallbackOscillators.chord) {
          // Stop all chord oscillators from enhanced music
          this.fallbackOscillators.chord.forEach(note => {
            note.oscillator.stop();
          });
          
          // Stop LFO for rhythm
          if (this.fallbackOscillators.lfo) {
            this.fallbackOscillators.lfo.stop();
          }
          
          console.log('Stopped enhanced fallback ambient music');
        } else if (this.fallbackOscillators.mainOscillator) {
          // Handle legacy structure (for backward compatibility)
          this.fallbackOscillators.mainOscillator.stop();
          this.fallbackOscillators.modulationOscillator.stop();
          console.log('Stopped basic fallback audio');
        }
        
        this.fallbackOscillators = null;
      } catch (e) {
        console.error('Failed to stop fallback oscillators:', e);
      }
    }
  },
  
  tryFallbackAudio() {
    console.log('Starting enhanced fallback music')
    this.backgroundMusicPlaying = false
    
    // Create a more complex ambient music using Web Audio API
    try {
      if (this.audioContext) {
        // Only attempt if Web Audio API is available
        this.resumeContext()
        
        // Create our main audio components
        const masterGain = this.audioContext.createGain()
        masterGain.gain.value = 0.15 // Master volume
        masterGain.connect(this.audioContext.destination)
        
        // Create a rich ambient chord with multiple oscillators
        const createChordOscillator = (frequency, type, gainValue) => {
          const osc = this.audioContext.createOscillator()
          const gain = this.audioContext.createGain()
          
          osc.type = type
          osc.frequency.value = frequency
          gain.gain.value = gainValue
          
          osc.connect(gain)
          gain.connect(masterGain)
          
          return { oscillator: osc, gain: gain }
        }
        
        // Create a gentle chord (based on Cmaj7 - C, E, G, B)
        const chord = [
          createChordOscillator(261.63, 'sine', 0.08),  // C4
          createChordOscillator(329.63, 'sine', 0.06),  // E4
          createChordOscillator(392.00, 'sine', 0.04),  // G4
          createChordOscillator(493.88, 'sine', 0.03)   // B4
        ]
        
        // Add some subtle rhythmic elements
        const lfoNode = this.audioContext.createOscillator()
        const lfoGain = this.audioContext.createGain()
        
        lfoNode.frequency.value = 0.07 // Very slow modulation
        lfoGain.gain.value = 0.1       // Subtle effect
        
        lfoNode.connect(lfoGain)
        lfoGain.connect(masterGain.gain)
        
        // Start all audio components
        chord.forEach(note => note.oscillator.start())
        lfoNode.start()
        
        // Store references for stopping later
        this.fallbackOscillators = {
          chord: chord,
          lfo: lfoNode,
          masterGain: masterGain
        }
        
        this.backgroundMusicPlaying = true
        console.log('Enhanced ambient music is now playing')
      }
    } catch (e) {
      console.error('Failed to create fallback audio:', e)
    }
  },

  playKeySound() {
    if (!this.soundEnabled || !this.typingSoundEnabled || !this.audioContext) return

    this.resumeContext()

    const oscillator = this.audioContext.createOscillator()
    const gainNode = this.audioContext.createGain()

    oscillator.connect(gainNode)
    gainNode.connect(this.audioContext.destination)

    // Softer, higher-pitched click for keystrokes
    oscillator.frequency.setValueAtTime(1200, this.audioContext.currentTime)
    oscillator.frequency.exponentialRampToValueAtTime(1400, this.audioContext.currentTime + 0.05)
    gainNode.gain.setValueAtTime(0.03, this.audioContext.currentTime)
    gainNode.gain.exponentialRampToValueAtTime(0.01, this.audioContext.currentTime + 0.05)

    oscillator.start()
    oscillator.stop(this.audioContext.currentTime + 0.05)
  },

  playSound(type) {
    if (!this.soundEnabled || !this.audioContext) return

    this.resumeContext()

    const oscillator = this.audioContext.createOscillator()
    const gainNode = this.audioContext.createGain()

    oscillator.connect(gainNode)
    gainNode.connect(this.audioContext.destination)

    // Different sounds for different events
    switch(type) {
      case 'correct':
        oscillator.frequency.setValueAtTime(800, this.audioContext.currentTime)
        oscillator.frequency.exponentialRampToValueAtTime(1000, this.audioContext.currentTime + 0.1)
        gainNode.gain.setValueAtTime(0.1, this.audioContext.currentTime)
        gainNode.gain.exponentialRampToValueAtTime(0.01, this.audioContext.currentTime + 0.1)
        oscillator.start()
        oscillator.stop(this.audioContext.currentTime + 0.1)
        break

      case 'incorrect':
        oscillator.frequency.setValueAtTime(300, this.audioContext.currentTime)
        oscillator.frequency.exponentialRampToValueAtTime(200, this.audioContext.currentTime + 0.2)
        gainNode.gain.setValueAtTime(0.15, this.audioContext.currentTime)
        gainNode.gain.exponentialRampToValueAtTime(0.01, this.audioContext.currentTime + 0.2)
        oscillator.start()
        oscillator.stop(this.audioContext.currentTime + 0.2)
        break

      case 'complete':
        // Play a cheerful completion sound
        const notes = [523, 659, 784, 1047] // C, E, G, C (major chord)
        notes.forEach((freq, index) => {
          const osc = this.audioContext.createOscillator()
          const gain = this.audioContext.createGain()

          osc.connect(gain)
          gain.connect(this.audioContext.destination)

          osc.frequency.setValueAtTime(freq, this.audioContext.currentTime + index * 0.1)
          gain.gain.setValueAtTime(0.1, this.audioContext.currentTime + index * 0.1)
          gain.gain.exponentialRampToValueAtTime(0.01, this.audioContext.currentTime + index * 0.1 + 0.3)

          osc.start(this.audioContext.currentTime + index * 0.1)
          osc.stop(this.audioContext.currentTime + index * 0.1 + 0.3)
        })
        break

      case 'levelup':
        // Ascending scale sound
        const scale = [523, 587, 659, 698, 784, 880, 988, 1047]
        scale.forEach((freq, index) => {
          const osc = this.audioContext.createOscillator()
          const gain = this.audioContext.createGain()

          osc.connect(gain)
          gain.connect(this.audioContext.destination)

          osc.frequency.setValueAtTime(freq, this.audioContext.currentTime + index * 0.08)
          gain.gain.setValueAtTime(0.08, this.audioContext.currentTime + index * 0.08)
          gain.gain.exponentialRampToValueAtTime(0.01, this.audioContext.currentTime + index * 0.08 + 0.15)

          osc.start(this.audioContext.currentTime + index * 0.08)
          osc.stop(this.audioContext.currentTime + index * 0.08 + 0.15)
        })
        break
    }
  }
}
