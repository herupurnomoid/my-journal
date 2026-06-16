package com.example.data.remote

import com.example.BuildConfig
import okhttp3.OkHttpClient
import okhttp3.logging.HttpLoggingInterceptor
import retrofit2.Retrofit
import retrofit2.converter.moshi.MoshiConverterFactory

object ApiClient {
    // Membaca BACKEND_BASE_URL dari BuildConfig (yang digenerate oleh Secrets Gradle Plugin dari .env)
    // Jika tidak ditemukan, defaultnya akan mengarah ke emulator (10.0.2.2)
    private val BASE_URL = try {
        BuildConfig.BACKEND_BASE_URL
    } catch (e: Exception) {
        "http://10.0.2.2:8080/api/"
    }

    private val loggingInterceptor = HttpLoggingInterceptor().apply {
        level = HttpLoggingInterceptor.Level.BODY
    }

    private val client = OkHttpClient.Builder()
        .addInterceptor(loggingInterceptor)
        .build()

    val retrofit: Retrofit by lazy {
        Retrofit.Builder()
            .baseUrl(BASE_URL)
            .client(client)
            .addConverterFactory(MoshiConverterFactory.create())
            .build()
    }

    val apiService: ApiService by lazy {
        retrofit.create(ApiService::class.java)
    }
}
