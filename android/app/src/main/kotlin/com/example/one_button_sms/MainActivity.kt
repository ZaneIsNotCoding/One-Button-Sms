package com.example.one_button_sms

import android.Manifest
import android.content.Context
import android.content.pm.PackageManager
import android.location.Criteria
import android.location.Location
import android.location.LocationListener
import android.location.LocationManager
import android.os.Bundle
import android.telephony.SmsManager
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val channelName = "one_button_sms/device"
    private val permissionRequestCode = 4810
    private var pendingPermissionResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            channelName
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "requestPermissions" -> requestNeededPermissions(result)
                "getLocation" -> getLocation(result)
                "sendSms" -> {
                    val recipients = call.argument<List<String>>("recipients").orEmpty()
                    val message = call.argument<String>("message").orEmpty()
                    sendSms(recipients, message, result)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun requestNeededPermissions(result: MethodChannel.Result) {
        if (hasNeededPermissions()) {
            result.success(true)
            return
        }

        pendingPermissionResult = result
        ActivityCompat.requestPermissions(
            this,
            arrayOf(
                Manifest.permission.ACCESS_FINE_LOCATION,
                Manifest.permission.ACCESS_COARSE_LOCATION,
                Manifest.permission.SEND_SMS
            ),
            permissionRequestCode
        )
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode != permissionRequestCode) return

        pendingPermissionResult?.success(hasNeededPermissions())
        pendingPermissionResult = null
    }

    private fun hasNeededPermissions(): Boolean {
        return hasPermission(Manifest.permission.ACCESS_FINE_LOCATION) &&
            hasPermission(Manifest.permission.SEND_SMS)
    }

    private fun hasPermission(permission: String): Boolean {
        return ContextCompat.checkSelfPermission(
            this,
            permission
        ) == PackageManager.PERMISSION_GRANTED
    }

    private fun getLocation(result: MethodChannel.Result) {
        if (!hasPermission(Manifest.permission.ACCESS_FINE_LOCATION)) {
            result.error("permission_denied", "Location permission is not granted.", null)
            return
        }

        val locationManager = getSystemService(Context.LOCATION_SERVICE) as LocationManager
        val providers = locationManager.getProviders(true)
        val lastKnown = providers
            .mapNotNull { provider -> locationManager.getLastKnownLocation(provider) }
            .maxByOrNull { location -> location.time }

        if (lastKnown != null) {
            result.success(locationToMap(lastKnown))
            return
        }

        val provider = locationManager.getBestProvider(Criteria().apply {
            accuracy = Criteria.ACCURACY_FINE
        }, true)

        if (provider == null) {
            result.error("location_unavailable", "No location provider is available.", null)
            return
        }

        val listener = object : LocationListener {
            override fun onLocationChanged(location: Location) {
                locationManager.removeUpdates(this)
                result.success(locationToMap(location))
            }

            override fun onProviderDisabled(provider: String) {
                locationManager.removeUpdates(this)
                result.error("location_unavailable", "Location provider is disabled.", null)
            }
        }

        locationManager.requestSingleUpdate(provider, listener, null)
    }

    private fun locationToMap(location: Location): Map<String, Double> {
        return mapOf(
            "latitude" to location.latitude,
            "longitude" to location.longitude
        )
    }

    private fun sendSms(
        recipients: List<String>,
        message: String,
        result: MethodChannel.Result
    ) {
        if (!hasPermission(Manifest.permission.SEND_SMS)) {
            result.error("permission_denied", "SMS permission is not granted.", null)
            return
        }

        if (recipients.isEmpty() || message.isBlank()) {
            result.success(0)
            return
        }

        val smsManager = SmsManager.getDefault()
        var sentCount = 0

        recipients
            .map { number -> number.trim() }
            .filter { number -> number.isNotEmpty() }
            .forEach { number ->
                val parts = smsManager.divideMessage(message)
                smsManager.sendMultipartTextMessage(number, null, parts, null, null)
                sentCount += 1
            }

        result.success(sentCount)
    }
}
