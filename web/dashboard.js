//
//  KaiSheng Dashboard JavaScript
//  Complete interactive dashboard with animations, state management, and API simulation
//

class KaiShengDashboard {
  constructor() {
    // Application state
    this.state = {
      // Motion tracking
      motion: {
        isWalking: false,
        stepCount: 0,
        walkStartTime: null,
        stepThreshold: 5,
        isTracking: false,
        currentPace: null
      },
      
      // App limits
      appLimits: [],
      currentUsage: [],
      isBlockingApps: false,
      
      // Downtime schedules
      downtimeSchedules: [],
      isInDowntime: false,
      activeDowntime: null,
      
      // Timer and intervals
      timers: {
        motionUpdate: null,
        usageUpdate: null,
        downtimeCheck: null,
        clockUpdate: null
      },
      
      // Settings
      theme: 'dark',
      notifications: true
    };
    
    // DOM elements cache
    this.elements = {};
    this.init();
  }
  
  // Initialize dashboard
  init() {
    this.cacheDOM();
    this.setupEventListeners();
    this.loadState();
    this.startAnimations();
    this.hideLoadingOverlay();
    this.log('KaiSheng Dashboard initialized');
  }
  
  // Cache DOM elements for performance
  cacheDOM() {
    // Main containers
    this.elements.dashboard = document.querySelector('.dashboard-container');
    this.elements.loadingOverlay = document.getElementById('loading-overlay');
    
    // Motion tracking
    this.elements.motionToggle = document.getElementById('motion-toggle');
    this.elements.motionStatus = document.getElementById('motion-status');
    this.elements.motionCircle = document.getElementById('motion-circle');
    this.elements.stepCount = document.getElementById('step-count');
    this.elements.walkDuration = document.getElementById('walk-duration');
    this.elements.stepThreshold = document.getElementById('step-threshold');
    this.elements.motionWarning = document.getElementById('motion-warning');
    
    // App limits
    this.elements.appSelector = document.getElementById('app-selector');
    this.elements.limitHours = document.getElementById('limit-hours');
    this.elements.limitMinutes = document.getElementById('limit-minutes');
    this.elements.addLimitBtn = document.getElementById('add-limit-btn');
    this.elements.limitsList = document.getElementById('limits-list');
    this.elements.limitsSummary = document.getElementById('limits-summary');
    this.elements.dailyTotal = document.getElementById('daily-total');
    this.elements.mostUsed = document.getElementById('most-used');
    
    // Downtime schedule
    this.elements.scheduleName = document.getElementById('schedule-name');
    this.elements.downtimeStart = document.getElementById('downtime-start');
    this.elements.downtimeEnd = document.getElementById('downtime-end');
    this.elements.addScheduleBtn = document.getElementById('add-schedule-btn');
    this.elements.schedulesList = document.getElementById('schedules-list');
    this.elements.downtimeStatus = document.getElementById('downtime-status');
    
    // Quick actions
    this.elements.emergencyOverride = document.getElementById('emergency-override');
    this.elements.pauseAll = document.getElementById('pause-all');
    this.elements.resetDay = document.getElementById('reset-day');
    this.elements.viewStats = document.getElementById('view-stats');
    
    // Settings
    this.elements.themeToggle = document.getElementById('theme-toggle');
    this.elements.settingsBtn = document.getElementById('settings-btn');
    
    // Glow and effects
    this.elements.cursorGlow = document.getElementById('cursor-glow');
    this.elements.particleCanvas = document.getElementById('particle-canvas');
  }
  
  // Setup event listeners
  setupEventListeners() {
    // Motion tracking
    this.elements.motionToggle.addEventListener('click', () => this.toggleMotionTracking());
    this.elements.stepThreshold.addEventListener('input', (e) => this.updateStepThreshold(e));
    
    // App limits
    this.elements.addLimitBtn.addEventListener('click', () => this.addAppLimit());
    this.elements.limitHours.addEventListener('input', (e) => this.validateTimeInput(e));
    this.elements.limitMinutes.addEventListener('input', (e) => this.validateTimeInput(e));
    
    // Downtime
    this.elements.addScheduleBtn.addEventListener('click', () => this.addDowntimeSchedule());
    
    // Quick actions
    this.elements.emergencyOverride.addEventListener('click', () => this.emergencyOverride());
    this.elements.pauseAll.addEventListener('click', () => this.pauseAllLimits());
    this.elements.resetDay.addEventListener('click', () => this.resetDay());
    this.elements.viewStats.addEventListener('click', () => this.viewStats());
    
    // Settings
    this.elements.themeToggle.addEventListener('click', () => this.toggleTheme());
    
    // Cursor glow effect
    document.addEventListener('mousemove', (e) => this.updateCursorGlow(e));
    document.addEventListener('mouseleave', () => this.hideCursorGlow());
    
    // Keyboard shortcuts
    document.addEventListener('keydown', (e) => this.handleKeyboardShortcuts(e));
    
    // Window events
    window.addEventListener('resize', this.debounce(() => this.handleResize(), 250));
    window.addEventListener('scroll', this.throttle(() => this.handleScroll(), 16));
  }
  
  // Motion Tracking
  toggleMotionTracking() {
    this.state.motion.isTracking = !this.state.motion.isTracking;
    
    if (this.state.motion.isTracking) {
      this.elements.motionToggle.innerHTML = `
        <span class="btn-icon">⏸</span>
        <span class="btn-text">Pause Tracking</span>
      `;
      this.elements.motionToggle.classList.add('active');
      this.startMotionDetection();
      this.log('Motion tracking started');
    } else {
      this.elements.motionToggle.innerHTML = `
        <span class="btn-icon">▶</span>
        <span class="btn-text">Start Tracking</span>
      `;
      this.elements.motionToggle.classList.remove('active');
      this.stopMotionDetection();
      this.log('Motion tracking paused');
    }
  }
  
  startMotionDetection() {
    // Simulate motion detection with accelerometer data
    this.state.timers.motionUpdate = setInterval(() => {
      this.simulateMotionData();
    }, 1000);
    
    this.log('Motion detection started');
  }
  
  stopMotionDetection() {
    if (this.state.timers.motionUpdate) {
      clearInterval(this.state.timers.motionUpdate);
      this.state.timers.motionUpdate = null;
    }
    
    // Reset motion state
    this.state.motion.isWalking = false;
    this.state.motion.stepCount = 0;
    this.state.motion.walkStartTime = null;
    this.updateMotionUI();
    
    this.log('Motion detection stopped');
  }
  
  simulateMotionData() {
    // Simulate acceleration data and walking detection
    const acceleration = Math.random() * 2 + 0.5; // Simulated acceleration
    const isWalkingNow = acceleration > 1.1;
    
    if (isWalkingNow && !this.state.motion.isWalking) {
      // Start walking
      this.state.motion.isWalking = true;
      this.state.motion.walkStartTime = Date.now();
      this.state.motion.stepCount = 0;
      this.log('Walking detected');
    } else if (!isWalkingNow && this.state.motion.isWalking) {
      // Stop walking
      this.state.motion.isWalking = false;
      this.state.motion.stepCount = 0;
      this.state.motion.walkStartTime = null;
      this.log('Walking stopped');
    }
    
    if (this.state.motion.isWalking) {
      // Simulate step counting
      this.state.motion.stepCount += Math.floor(Math.random() * 2);
      this.state.motion.currentPace = Math.random() * 2 + 0.5;
    }
    
    this.updateMotionUI();
    this.checkMotionRestrictions();
  }
  
  updateMotionUI() {
    // Update motion status
    this.elements.motionStatus.setAttribute('data-active', this.state.motion.isWalking);
    this.elements.motionStatus.querySelector('.status-text').textContent = 
      this.state.motion.isWalking ? 'Walking Detected' : 'No Motion';
    
    // Update motion circle
    this.elements.motionCircle.classList.toggle('active', this.state.motion.isWalking);
    
    // Update step count
    this.elements.stepCount.textContent = this.state.motion.stepCount.toLocaleString();
    
    // Update walk duration
    if (this.state.motion.walkStartTime) {
      const duration = Date.now() - this.state.motion.walkStartTime;
      const minutes = Math.floor(duration / 60000);
      const seconds = Math.floor((duration % 60000) / 1000);
      this.elements.walkDuration.textContent = `${minutes}m ${seconds}s`;
    } else {
      this.elements.walkDuration.textContent = '0m 0s';
    }
    
    // Animate step count updates
    this.animateStepCount();
  }
  
  animateStepCount() {
    const element = this.elements.stepCount;
    element.style.transform = 'scale(1.2)';
    element.style.transition = 'transform 0.3s var(--spring-bounce)';
    
    setTimeout(() => {
      element.style.transform = 'scale(1)';
    }, 300);
  }
  
  checkMotionRestrictions() {
    const shouldRestrict = this.state.motion.isWalking && 
                          this.state.motion.stepCount >= this.state.motion.stepThreshold;
    
    if (shouldRestrict) {
      this.elements.motionWarning.hidden = false;
      this.showNotification('Social media scrolling restricted while walking', 'warning');
      this.log('Social media restrictions applied due to walking');
    } else {
      this.elements.motionWarning.hidden = true;
    }
  }
  
  updateStepThreshold(event) {
    this.state.motion.stepThreshold = parseInt(event.target.value);
    this.elements.stepThreshold.nextElementSibling.textContent = this.state.motion.stepThreshold;
    this.log(`Step threshold updated to ${this.state.motion.stepThreshold}`);
  }
  
  // App Limits
  addAppLimit() {
    const appName = this.elements.appSelector.value;
    const hours = parseInt(this.elements.limitHours.value) || 0;
    const minutes = parseInt(this.elements.limitMinutes.value) || 0;
    
    if (!appName) {
      this.showNotification('Please select an app', 'error');
      return;
    }
    
    const limitSeconds = hours * 3600 + minutes * 60;
    if (limitSeconds === 0) {
      this.showNotification('Please set a time limit', 'error');
      return;
    }
    
    // Check if limit already exists
    const existingLimit = this.state.appLimits.find(limit => limit.appName === appName);
    if (existingLimit) {
      this.showNotification('Limit already exists for this app', 'error');
      return;
    }
    
    // Create new limit
    const newLimit = {
      id: this.generateId(),
      appName,
      dailyLimit: limitSeconds,
      category: this.getAppCategory(appName),
      usageTime: 0,
      createdAt: new Date()
    };
    
    this.state.appLimits.push(newLimit);
    this.renderAppLimits();
    this.updateUsageStats();
    this.saveState();
    
    // Reset form
    this.elements.appSelector.value = '';
    this.elements.limitHours.value = 1;
    this.elements.limitMinutes.value = 0;
    
    this.showNotification(`Added ${hours}h ${minutes}m limit for ${appName}`, 'success');
    this.log(`App limit added: ${appName} - ${hours}h ${minutes}m`);
  }
  
  removeAppLimit(limitId) {
    this.state.appLimits = this.state.appLimits.filter(limit => limit.id !== limitId);
    this.renderAppLimits();
    this.updateUsageStats();
    this.saveState();
    
    this.showNotification('App limit removed', 'success');
    this.log('App limit removed');
  }
  
  updateAppLimit(limitId, newLimit) {
    const index = this.state.appLimits.findIndex(limit => limit.id === limitId);
    if (index !== -1) {
      this.state.appLimits[index] = { ...this.state.appLimits[index], ...newLimit };
      this.renderAppLimits();
      this.saveState();
    }
  }
  
  renderAppLimits() {
    this.elements.limitsList.innerHTML = '';
    
    this.state.appLimits.forEach(limit => {
      const usagePercentage = (limit.usageTime / limit.dailyLimit) * 100;
      const isBlocked = usagePercentage >= 100;
      const isWarning = usagePercentage >= 80 && usagePercentage < 100;
      const isDanger = usagePercentage >= 90;
      
      const limitItem = this.createElement('div', {
        className: `limit-item ${isBlocked ? 'blocked' : ''}`,
        innerHTML: `
          <div class="limit-header">
            <div class="limit-info">
              <span class="limit-name">${limit.appName}</span>
              <span class="limit-category">${limit.category}</span>
            </div>
            ${isBlocked ? '<svg class="lock-icon" viewBox="0 0 24 24" fill="currentColor"><path d="M18 8h-1V6c0-2.76-2.24-5-5-5S7 3.24 7 6v2H6c-1.1 0-2 .9-2 2v10c0 1.1.9 2 2 2h12c1.1 0 2-.9 2-2V10c0-1.1-.9-2-2-2zm-6 9c-1.1 0-2-.9-2-2s.9-2 2-2 2 .9 2 2-.9 2-2 2zm3.1-9H8.9V6c0-1.71 1.39-3.1 3.1-3.1 1.71 0 3.1 1.39 3.1 3.1v2z"/></svg>' : ''}
          </div>
          
          <div class="limit-progress">
            <div class="progress-bar">
              <div class="progress-fill ${isDanger ? 'danger' : isWarning ? 'warning' : ''}" 
                   style="width: ${Math.min(usagePercentage, 100)}%"></div>
            </div>
          </div>
          
          <div class="limit-details">
            <span class="limit-usage">${this.formatTime(limit.usageTime)} / ${this.formatTime(limit.dailyLimit)}</span>
            <div class="limit-actions">
              <button class="icon-btn edit-limit" data-limit-id="${limit.id}" 
                      aria-label="Edit limit">
                <svg viewBox="0 0 24 24" fill="currentColor">
                  <path d="M3 17.25V21h3.75L17.81 9.94l-3.75-3.75L3 17.25zM20.71 7.04c.39-.39.39-1.02 0-1.41l-2.34-2.34c-.39-.39-1.02-.39-1.41 0l-1.83 1.83 3.75 3.75 1.83-1.83z"/>
                </svg>
              </button>
              <button class="icon-btn remove-limit" data-limit-id="${limit.id}" 
                      aria-label="Remove limit">
                <svg viewBox="0 0 24 24" fill="currentColor">
                  <path d="M6 19c0 1.1.9 2 2 2h8c1.1 0 2-.9 2-2V7H6v12zM19 4h-3.5l-1-1h-5l-1 1H5v2h14V4z"/>
                </svg>
              </button>
            </div>
          </div>
        `
      });
      
      // Add event listeners to buttons
      const removeBtn = limitItem.querySelector('.remove-limit');
      removeBtn.addEventListener('click', () => this.removeAppLimit(limit.id));
      
      this.elements.limitsList.appendChild(limitItem);
    });
    
    // Update summary
    this.elements.limitsSummary.textContent = `${this.state.appLimits.length} active limits`;
    
    // Animate progress bars
    setTimeout(() => {
      const progressBars = this.elements.limitsList.querySelectorAll('.progress-fill');
      progressBars.forEach(bar => {
        bar.style.width = bar.style.width;
      });
    }, 100);
  }
  
  simulateAppUsage() {
    // Simulate app usage over time
    this.state.appLimits.forEach(limit => {
      if (Math.random() < 0.3) { // 30% chance of usage
        const usageIncrement = Math.floor(Math.random() * 180) + 60; // 1-4 minutes
        limit.usageTime = Math.min(limit.usageTime + usageIncrement, limit.dailyLimit + 600);
        
        // Check for limit exceeded
        if (limit.usageTime >= limit.dailyLimit) {
          this.showNotification(`${limit.appName} time limit exceeded`, 'warning');
        }
      }
    });
    
    this.renderAppLimits();
    this.updateUsageStats();
    this.saveState();
  }
  
  updateUsageStats() {
    const totalUsage = this.state.appLimits.reduce((sum, limit) => sum + limit.usageTime, 0);
    this.elements.dailyTotal.textContent = this.formatTime(totalUsage);
    
    const mostUsed = this.state.appLimits.reduce((max, limit) => 
      limit.usageTime > max.usageTime ? limit : max, this.state.appLimits[0] || { appName: 'None', usageTime: 0 });
    
    this.elements.mostUsed.textContent = mostUsed.appName;
  }
  
  // Downtime Schedules
  addDowntimeSchedule() {
    const name = this.elements.scheduleName.value;
    const startTime = this.elements.downtimeStart.value;
    const endTime = this.elements.downtimeEnd.value;
    
    if (!name) {
      this.showNotification('Please enter a schedule name', 'error');
      return;
    }
    
    // Get selected days
    const selectedDays = Array.from(document.querySelectorAll('.day-checkbox input:checked'))
      .map(cb => cb.value);
    
    if (selectedDays.length === 0) {
      this.showNotification('Please select at least one day', 'error');
      return;
    }
    
    const isRecurring = true; // Always recurring for MVP
    const blockEntireDevice = document.getElementById('block-device').checked;
    
    // Mock blocked apps for now
    const blockedApps = blockEntireDevice ? []
      : ['Instagram', 'TikTok', 'Facebook', 'Twitter'];
    
    const newSchedule = {
      id: this.generateId(),
      name,
      startTime: this.parseTime(startTime),
      endTime: this.parseTime(endTime),
      isRecurring,
      recurringDays: new Set(selectedDays),
      blockedApps,
      blockEntireDevice,
      createdAt: new Date()
    };
    
    this.state.downtimeSchedules.push(newSchedule);
    this.renderDowntimeSchedules();
    this.checkDowntimeStatus();
    this.saveState();
    
    // Reset form
    this.elements.scheduleName.value = '';
    this.elements.downtimeStart.value = '21:00';
    this.elements.downtimeEnd.value = '07:00';
    document.querySelectorAll('.day-checkbox input').forEach(cb => cb.checked = false);
    document.getElementById('block-device').checked = false;
    
    this.showNotification(`Downtime schedule "${name}" added`, 'success');
    this.log(`Downtime schedule added: ${name}`);
  }
  
  removeDowntimeSchedule(scheduleId) {
    this.state.downtimeSchedules = this.state.downtimeSchedules.filter(
      schedule => schedule.id !== scheduleId
    );
    this.renderDowntimeSchedules();
    this.checkDowntimeStatus();
    this.saveState();
    
    this.showNotification('Downtime schedule removed', 'success');
    this.log('Downtime schedule removed');
  }
  
  renderDowntimeSchedules() {
    this.elements.schedulesList.innerHTML = '';
    
    this.state.downtimeSchedules.forEach(schedule => {
      const isActive = this.isScheduleActive(schedule);
      const timeRange = this.formatTimeRange(schedule.startTime, schedule.endTime);
      const dayNames = Array.from(schedule.recurringDays).join(', ');
      
      const scheduleItem = this.createElement('div', {
        className: `schedule-item ${isActive ? 'active' : ''}`,
        innerHTML: `
          <div class="schedule-header">
            <div class="schedule-name">
              ${schedule.name}
              <span class="schedule-status ${isActive ? 'active' : ''}">
                ${isActive ? 'Active' : 'Inactive'}
              </span>
            </div>
            <div class="schedule-actions">
              <button class="icon-btn remove-schedule" data-schedule-id="${schedule.id}" 
                      aria-label="Remove schedule">
                <svg viewBox="0 0 24 24" fill="currentColor">
                  <path d="M6 19c0 1.1.9 2 2 2h8c1.1 0 2-.9 2-2V7H6v12zM19 4h-3.5l-1-1h-5l-1 1H5v2h14V4z"/>
                </svg>
              </button>
            </div>
          </div>
          
          <div class="schedule-time">${timeRange}</div>
          
          <div class="schedule-days">${dayNames}</div>
        `
      });
      
      // Add event listeners
      const removeBtn = scheduleItem.querySelector('.remove-schedule');
      removeBtn.addEventListener('click', () => this.removeDowntimeSchedule(schedule.id));
      
      this.elements.schedulesList.appendChild(scheduleItem);
    });
  }
  
  checkDowntimeStatus() {
    const now = new Date();
    let activeSchedule = null;
    
    for (const schedule of this.state.downtimeSchedules) {
      if (this.isScheduleActive(schedule)) {
        activeSchedule = schedule;
        break;
      }
    }
    
    const wasInDowntime = this.state.isInDowntime;
    this.state.isInDowntime = activeSchedule !== null;
    this.state.activeDowntime = activeSchedule;
    
    // Update UI
    this.elements.downtimeStatus.setAttribute('data-active', this.state.isInDowntime);
    this.elements.downtimeStatus.querySelector('.status-text').textContent = 
      this.state.isInDowntime ? 'Active' : 'Inactive';
    
    // Trigger notifications
    if (!wasInDowntime && this.state.isInDowntime) {
      this.showNotification(`Downtime started: ${activeSchedule.name}`, 'warning');
    } else if (wasInDowntime && !this.state.isInDowntime) {
      this.showNotification('Downtime period ended', 'success');
    }
    
    this.renderDowntimeSchedules();
  }
  
  isScheduleActive(schedule) {
    const now = new Date();
    const currentTime = now.getHours() * 60 + now.getMinutes();
    const startTime = schedule.startTime.getHours() * 60 + schedule.startTime.getMinutes();
    const endTime = schedule.endTime.getHours() * 60 + schedule.endTime.getMinutes();
    
    let isTimeActive;
    if (startTime <= endTime) {
      isTimeActive = currentTime >= startTime && currentTime < endTime;
    } else {
      // Overnight schedule
      isTimeActive = currentTime >= startTime || currentTime < endTime;
    }
    
    if (!isTimeActive) return false;
    
    // Check day of week
    const days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    const currentDay = days[now.getDay()];
    
    return schedule.recurringDays.has(currentDay);
  }
  
  // Quick Actions
  emergencyOverride() {
    this.state.isBlockingApps = false;
    
    // Temporarily disable all limits
    this.state.appLimits.forEach(limit => {
      limit.usageTime = Math.min(limit.usageTime, limit.dailyLimit - 60);
    });
    
    this.renderAppLimits();
    this.showNotification('Emergency override activated - all apps unblocked for 5 minutes', 'success');
    this.log('Emergency override activated');
    
    // Re-enable after 5 minutes
    setTimeout(() => {
      this.checkLimitsAndBlockApps();
      this.showNotification('Emergency override expired', 'warning');
    }, 300000);
  }
  
  pauseAllLimits() {
    const isPaused = this.state.isBlockingApps;
    this.state.isBlockingApps = !isPaused;
    
    const action = isPaused ? 'resumed' : 'paused';
    this.showNotification(`All limits ${action}`, 'success');
    this.log(`All limits ${action}`);
    
    // Update button state
    const icon = this.elements.pauseAll.querySelector('.action-icon');
    icon.style.background = isPaused ? '' : 'var(--gradient-secondary)';
  }
  
  resetDay() {
    // Reset all usage data
    this.state.appLimits.forEach(limit => {
      limit.usageTime = 0;
    });
    
    this.state.motion.stepCount = 0;
    this.state.motion.walkStartTime = null;
    this.state.motion.isWalking = false;
    
    this.renderAppLimits();
    this.updateMotionUI();
    this.updateUsageStats();
    this.saveState();
    
    this.showNotification('Daily usage reset', 'success');
    this.log('Daily usage reset');
  }
  
  viewStats() {
    const stats = this.generateUsageStats();
    this.showStatsModal(stats);
    this.log('View stats clicked');
  }
  
  // Theme Management
  toggleTheme() {
    const currentTheme = document.documentElement.getAttribute('data-theme');
    const newTheme = currentTheme === 'light' ? 'dark' : 'light';
    
    document.documentElement.setAttribute('data-theme', newTheme);
    this.state.theme = newTheme;
    this.saveState();
    
    this.log(`Theme changed to ${newTheme}`);
  }
  
  loadTheme() {
    const savedTheme = this.state.theme || 'dark';
    document.documentElement.setAttribute('data-theme', savedTheme);
  }
  
  // UI Effects
  updateCursorGlow(event) {
    const glow = this.elements.cursorGlow;
    glow.classList.add('active');
    
    const x = event.clientX;
    const y = event.clientY;
    
    glow.style.left = `${x}px`;
    glow.style.top = `${y}px`;
    
    // Calculate proximity to interactive elements
    const interactiveElements = document.querySelectorAll('button, input, select, .action-btn');
    let maxGlow = 0.3;
    
    interactiveElements.forEach(element => {
      const rect = element.getBoundingClientRect();
      const centerX = rect.left + rect.width / 2;
      const centerY = rect.top + rect.height / 2;
      
      const distance = Math.sqrt(Math.pow(x - centerX, 2) + Math.pow(y - centerY, 2));
      const glowIntensity = Math.max(0, 1 - distance / 150);
      maxGlow = Math.max(maxGlow, glowIntensity * 0.6);
    });
    
    glow.style.opacity = maxGlow;
  }
  
  hideCursorGlow() {
    this.elements.cursorGlow.classList.remove('active');
  }
  
  startAnimations() {
    // Initialize particle system
    this.initParticleSystem();
    
    // Stagger card animations
    this.staggerCardAnimations();
    
    // Start periodic checks
    this.startPeriodicChecks();
  }
  
  initParticleSystem() {
    const canvas = this.elements.particleCanvas;
    const ctx = canvas.getContext('2d');
    
    canvas.width = window.innerWidth;
    canvas.height = window.innerHeight;
    
    const particles = [];
    const particleCount = 50;
    
    // Create particles
    for (let i = 0; i < particleCount; i++) {
      particles.push({
        x: Math.random() * canvas.width,
        y: Math.random() * canvas.height,
        vx: (Math.random() - 0.5) * 0.5,
        vy: (Math.random() - 0.5) * 0.5,
        size: Math.random() * 2 + 1,
        opacity: Math.random() * 0.5 + 0.2
      });
    }
    
    // Animate particles
    const animate = () => {
      ctx.clearRect(0, 0, canvas.width, canvas.height);
      
      particles.forEach(particle => {
        particle.x += particle.vx;
        particle.y += particle.vy;
        
        // Wrap around edges
        if (particle.x < 0) particle.x = canvas.width;
        if (particle.x > canvas.width) particle.x = 0;
        if (particle.y < 0) particle.y = canvas.height;
        if (particle.y > canvas.height) particle.y = 0;
        
        // Draw particle
        ctx.beginPath();
        ctx.arc(particle.x, particle.y, particle.size, 0, Math.PI * 2);
        ctx.fillStyle = `rgba(102, 126, 234, ${particle.opacity})`;
        ctx.fill();
      });
      
      requestAnimationFrame(animate);
    };
    
    animate();
    
    // Handle resize
    window.addEventListener('resize', () => {
      canvas.width = window.innerWidth;
      canvas.height = window.innerHeight;
    });
  }
  
  staggerCardAnimations() {
    const cards = document.querySelectorAll('.feature-card');
    cards.forEach((card, index) => {
      card.style.setProperty('--card-index', index);
    });
  }
  
  startPeriodicChecks() {
    // Check downtime status every minute
    this.state.timers.downtimeCheck = setInterval(() => {
      this.checkDowntimeStatus();
    }, 60000);
    
    // Simulate app usage every 30 seconds
    this.state.timers.usageUpdate = setInterval(() => {
      this.simulateAppUsage();
    }, 30000);
    
    // Update clock every second (for time display)
    this.state.timers.clockUpdate = setInterval(() => {
      this.updateTimeDisplays();
    }, 1000);
  }
  
  updateTimeDisplays() {
    // Update any time-based displays
    const timeElements = document.querySelectorAll('[data-current-time]');
    timeElements.forEach(element => {
      element.textContent = new Date().toLocaleTimeString();
    });
  }

  // Utility Functions
  generateId() {
    return 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, function(c) {
      const r = Math.random() * 16 | 0;
      const v = c === 'x' ? r : (r & 0x3 | 0x8);
      return v.toString(16);
    });
  }
  
  getAppCategory(appName) {
    const categories = {
      'SOCIAL': ['Instagram', 'TikTok', 'Facebook', 'Twitter', 'Snapchat', 'Reddit', 'WhatsApp'],
      'ENTERTAINMENT': ['YouTube', 'Netflix', 'Spotify', 'Games'],
      'PRODUCTIVITY': [],
      'OTHER': []
    };
    
    for (const [category, apps] of Object.entries(categories)) {
      if (apps.includes(appName)) {
        return category;
      }
    }
    
    return 'OTHER';
  }
  
  formatTime(seconds) {
    const hours = Math.floor(seconds / 3600);
    const minutes = Math.floor((seconds % 3600) / 60);
    
    if (hours > 0) {
      return `${hours}h ${minutes}m`;
    } else {
      return `${minutes}m`;
    }
  }
  
  formatTimeRange(startTime, endTime) {
    const start = startTime.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' });
    const end = endTime.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' });
    return `${start} - ${end}`;
  }
  
  parseTime(timeString) {
    const [hours, minutes] = timeString.split(':').map(Number);
    const date = new Date();
    date.setHours(hours, minutes, 0, 0);
    return date;
  }
  
  validateTimeInput(event) {
    const input = event.target;
    const max = parseInt(input.getAttribute('max'));
    const value = parseInt(input.value) || 0;
    
    if (value > max) {
      input.value = max;
    } else if (value < 0) {
      input.value = 0;
    }
  }
  
  createElement(tag, options = {}) {
    const element = document.createElement(tag);
    Object.assign(element, options);
    return element;
  }
  
  showNotification(message, type = 'info') {
    // Create notification element
    const notification = this.createElement('div', {
      className: `notification notification-${type}`,
      innerHTML: `
        <div class="notification-content">
          <span>${message}</span>
          <button class="notification-close">&times;</button>
        </div>
      `
    });
    
    // Add styles
    Object.assign(notification.style, {
      position: 'fixed',
      top: '20px',
      right: '20px',
      padding: '16px 24px',
      borderRadius: '12px',
      color: 'white',
      fontWeight: '500',
      zIndex: '10000',
      transform: 'translateX(400px)',
      transition: 'transform 0.3s var(--spring-bounce)',
      boxShadow: '0 8px 32px rgba(0,0,0,0.3)',
      backdropFilter: 'blur(12px)',
      border: '1px solid rgba(255,255,255,0.1)'
    });
    
    // Set background based on type
    const backgroundColor = {
      success: 'var(--success)',
      warning: 'var(--warning)',
      error: 'var(--error)',
      info: 'var(--info)'
    }[type];
    
    notification.style.background = backgroundColor;
    
    // Add to DOM
    document.body.appendChild(notification);
    
    // Animate in
    setTimeout(() => {
      notification.style.transform = 'translateX(0)';
    }, 100);
    
    // Auto remove
    setTimeout(() => {
      notification.style.transform = 'translateX(400px)';
      setTimeout(() => {
        if (notification.parentNode) {
          notification.parentNode.removeChild(notification);
        }
      }, 300);
    }, 4000);
    
    // Close button
    const closeBtn = notification.querySelector('.notification-close');
    closeBtn.addEventListener('click', () => {
      notification.style.transform = 'translateX(400px)';
      setTimeout(() => {
        if (notification.parentNode) {
          notification.parentNode.removeChild(notification);
        }
      }, 300);
    });
  }
  
  // Debounce and throttle utilities
  debounce(func, wait) {
    let timeout;
    return function executedFunction(...args) {
      const later = () => {
        clearTimeout(timeout);
        func(...args);
      };
      clearTimeout(timeout);
      timeout = setTimeout(later, wait);
    };
  }
  
  throttle(func, limit) {
    let inThrottle;
    return function executedFunction(...args) {
      if (!inThrottle) {
        func.apply(this, args);
        inThrottle = true;
        setTimeout(() => inThrottle = false, limit);
      }
    };
  }
  
  // Keyboard shortcuts
  handleKeyboardShortcuts(event) {
    if (event.ctrlKey || event.metaKey) {
      switch (event.key) {
        case 'm':
          event.preventDefault();
          this.toggleMotionTracking();
          break;
        case 'r':
          event.preventDefault();
          this.resetDay();
          break;
        case 'p':
          event.preventDefault();
          this.pauseAllLimits();
          break;
      }
    }
  }
  
  handleResize() {
    // Handle responsive changes
    this.log('Window resized');
  }
  
  handleScroll() {
    // Handle scroll animations
    const cards = document.querySelectorAll('.feature-card');
    cards.forEach(card => {
      const rect = card.getBoundingClientRect();
      const isVisible = rect.top < window.innerHeight * 0.8;
      
      if (isVisible) {
        card.classList.add('revealed');
      }
    });
  }
  
  hideLoadingOverlay() {
    setTimeout(() => {
      this.elements.loadingOverlay.classList.add('hidden');
      setTimeout(() => {
        this.elements.loadingOverlay.style.display = 'none';
      }, 500);
    }, 2000);
  }
  
  // State Management
  saveState() {
    try {
      localStorage.setItem('kaisheng-state', JSON.stringify(this.state));
    } catch (error) {
      console.warn('Failed to save state:', error);
    }
  }
  
  loadState() {
    try {
      const savedState = localStorage.getItem('kaisheng-state');
      if (savedState) {
        const parsed = JSON.parse(savedState);
        // Merge saved state with current state
        this.state = { ...this.state, ...parsed };
        
        // Restore UI state
        this.loadTheme();
        this.renderAppLimits();
        this.renderDowntimeSchedules();
        this.updateMotionUI();
        this.updateUsageStats();
        this.checkDowntimeStatus();
      }
    } catch (error) {
      console.warn('Failed to load state:', error);
    }
  }
  
  // Logging
  log(message) {
    const timestamp = new Date().toLocaleTimeString();
    console.log(`[KaiSheng ${timestamp}] ${message}`);
  }
}

// Initialize dashboard when DOM is ready
if (document.readyState === 'loading') {
  document.addEventListener('DOMContentLoaded', () => {
    window.kaishengDashboard = new KaiShengDashboard();
  });
} else {
  window.kaishengDashboard = new KaiShengDashboard();
}

// Service Worker for offline support (optional)
if ('serviceWorker' in navigator) {
  navigator.serviceWorker.register('/sw.js').catch(console.error);
}