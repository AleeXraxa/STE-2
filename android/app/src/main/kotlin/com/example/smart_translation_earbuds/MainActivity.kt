package com.example.smart_translation_earbuds

import android.Manifest
import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothProfile
import android.content.pm.PackageManager
import android.os.Build
import androidx.core.app.ActivityCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val channelName = "classic_bluetooth"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "getConnectedAudioDeviceName" -> getConnectedAudioDeviceName(result)
                    else -> result.notImplemented()
                }
            }
    }

    private fun getConnectedAudioDeviceName(result: MethodChannel.Result) {
        val adapter = BluetoothAdapter.getDefaultAdapter()
        if (adapter == null || !adapter.isEnabled) {
            result.success(null)
            return
        }

        if (!hasBluetoothConnectPermission()) {
            result.success(null)
            return
        }

        val profiles = listOf(BluetoothProfile.A2DP, BluetoothProfile.HEADSET)
        queryProfiles(adapter, profiles, result)
    }

    private fun queryProfiles(
        adapter: BluetoothAdapter,
        profiles: List<Int>,
        result: MethodChannel.Result
    ) {
        if (profiles.isEmpty()) {
            result.success(null)
            return
        }

        val profile = profiles.first()
        adapter.getProfileProxy(
            this,
            object : BluetoothProfile.ServiceListener {
                override fun onServiceConnected(profileType: Int, proxy: BluetoothProfile) {
                    val devices = proxy.connectedDevices
                    adapter.closeProfileProxy(profileType, proxy)

                    if (devices.isNotEmpty()) {
                        val name = devices.first().name
                        result.success(name)
                    } else {
                        queryProfiles(adapter, profiles.drop(1), result)
                    }
                }

                override fun onServiceDisconnected(profileType: Int) {
                    queryProfiles(adapter, profiles.drop(1), result)
                }
            },
            profile
        )
    }

    private fun hasBluetoothConnectPermission(): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.S) {
            return true
        }
        return ActivityCompat.checkSelfPermission(
            this,
            Manifest.permission.BLUETOOTH_CONNECT
        ) == PackageManager.PERMISSION_GRANTED
    }
}
