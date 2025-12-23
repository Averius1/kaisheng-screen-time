package com.kaisheng.service

import android.content.Context
import android.hardware.Sensor
import android.hardware.SensorEvent
import android.hardware.SensorEventListener
import android.hardware.SensorManager
import android.os.Handler
import android.os.Looper
import androidx.compose.runtime.State
import androidx.compose.runtime.mutableStateOf
import androidx.lifecycle.ViewModel
import java.util.UUID
import kotlin.math.sqrt

class MotionManager(context: Context) : ViewModel(), SensorEventListener {
    
    companion object {
        private const val WALKING_ACCELERATION_THRESHOLD = 1.1f
        private const val WALKING_STEP_THRESHOLD = 5
        private const val DETECTION_DELAY_MS = 3000L
        private const val STOP_DELAY_MS = 2000L
    }
    
    private val sensorManager = context.getSystemService(Context.SENSOR_SERVICE) as SensorManager
    private val accelerometer = sensorManager.getDefaultSensor(Sensor.TYPE_ACCELEROMETER)
    
    // State management using Compose State (similar to @Published in iOS)
    private val _isWalking = mutableStateOf(false)
    val isWalking: State<Boolean> = _isWalking
    
    private val _walkStartTime = mutableStateOf<Long?>(null)
    val walkStartTime: State<Long?> = _walkStartTime
    
    private val _stepCount = mutableStateOf(0)
    val stepCount: State<Int> = _stepCount
    
    private var detectionHandler: Handler? = null
    private var stopHandler: Handler? = null
    private var lastAcceleration = 0f
    private var motionDetected = false
    
    init {
        startMotionUpdates()
    }
    
    fun startMotionUpdates() {
        if (accelerometer != null) {
            // Register sensor listener with normal delay (game would be too fast)
            sensorManager.registerListener(
                this,
                accelerometer,
                SensorManager.SENSOR_DELAY_NORMAL
            )
        }
    }
    
    fun stopMotionUpdates() {
        sensorManager.unregisterListener(this)
        detectionHandler?.removeCallbacksAndMessages(null)
        stopHandler?.removeCallbacksAndMessages(null)
    }
    
    override fun onSensorChanged(event: SensorEvent) {
        if (event.sensor.type == Sensor.TYPE_ACCELEROMETER) {
            val acceleration = calculateTotalAcceleration(event)
            processAcceleration(acceleration)
        }
    }
    
    override fun onAccuracyChanged(sensor: Sensor, accuracy: Int) {
        // Not used in MVP
    }
    
    private fun calculateTotalAcceleration(event: SensorEvent): Float {
        val x = event.values[0]
        val y = event.values[1]
        val z = event.values[2]
        return sqrt(x * x + y * y + z * z)
    }
    
    private fun processAcceleration(acceleration: Float) {
        lastAcceleration = acceleration
        
        // Detect walking based on acceleration threshold
        if (acceleration > WALKING_ACCELERATION_THRESHOLD) {
            if (!_isWalking.value) {
                startWalkingDetection()
            }
            motionDetected = true
        } else {
            // If acceleration drops below threshold, prepare to stop walking
            if (_isWalking.value && motionDetected) {
                stopWalkingDetection()
            }
            motionDetected = false
        }
    }
    
    private fun startWalkingDetection() {
        // Cancel any existing detection timer
        detectionHandler?.removeCallbacksAndMessages(null)
        
        // Start detection after delay to prevent false positives
        detectionHandler = Handler(Looper.getMainLooper())
        detectionHandler?.postDelayed({
            if (lastAcceleration > WALKING_ACCELERATION_THRESHOLD) {
                setWalkingStatus(true)
            }
        }, DETECTION_DELAY_MS)
    }
    
    private fun stopWalkingDetection() {
        // Cancel any existing stop timer
        stopHandler?.removeCallbacksAndMessages(null)
        
        // Stop walking after delay to prevent rapid on/off
        stopHandler = Handler(Looper.getMainLooper())
        stopHandler?.postDelayed({
            setWalkingStatus(false)
        }, STOP_DELAY_MS)
    }
    
    private fun setWalkingStatus(walking: Boolean) {
        if (walking && !_isWalking.value) {
            // Start walking
            _isWalking.value = true
            _walkStartTime.value = System.currentTimeMillis()
            notifyWalkingStarted()
            
            // Simulate step counting (in real implementation, use step counter sensor)
            startSimulatedStepCounting()
            
        } else if (!walking && _isWalking.value) {
            // Stop walking
            _isWalking.value = false
            _walkStartTime.value = null
            _stepCount.value = 0
            notifyWalkingEnded()
        }
    }
    
    private fun startSimulatedStepCounting() {
        // Simulate step counting with periodic updates
        val stepHandler = Handler(Looper.getMainLooper())
        val stepRunnable = object : Runnable {
            override fun run() {
                if (_isWalking.value) {
                    _stepCount.value = _stepCount.value + 1
                    stepHandler.postDelayed(this, 800) // ~75 steps per minute
                }
            }
        }
        stepHandler.post(stepRunnable)
    }
    
    private fun notifyWalkingStarted() {
        // Notify app components that walking has started
        // In Compose apps, state changes automatically trigger UI updates
        android.util.Log.d("MotionManager", "Walking started")
    }
    
    private fun notifyWalkingEnded() {
        // Notify app components that walking has ended
        android.util.Log.d("MotionManager", "Walking ended")
    }
    
    // Public API methods
    
    fun getWalkingDuration(): Long {
        val startTime = _walkStartTime.value
        return if (startTime != null) {
            (System.currentTimeMillis() - startTime) / 1000 // Return seconds
        } else {
            0
        }
    }
    
    fun shouldRestrictScrolling(): Boolean {
        return _isWalking.value && _stepCount.value >= WALKING_STEP_THRESHOLD
    }
    
    fun resetStepCount() {
        _stepCount.value = 0
    }
    
    override fun onCleared() {
        super.onCleared()
        stopMotionUpdates()
    }
}

// Extension to make MotionManager observable in Compose
fun MotionManager.isWalkingState(): State<Boolean> = isWalking
fun MotionManager.stepCountState(): State<Int> = stepCount
fun MotionManager.walkStartTimeState(): State<Long?> = walkStartTime