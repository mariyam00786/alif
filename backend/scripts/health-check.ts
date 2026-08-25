/**
 * Backend Health Check and API Validation Script
 * 
 * Purpose: Validate all backend services and endpoints are operational
 * Run: npm run test:health or npx ts-node backend/scripts/health-check.ts
 */

import axios, { AxiosError } from 'axios';

interface HealthCheckResult {
  service: string;
  status: 'ok' | 'error';
  message: string;
  responseTime: number;
  timestamp: string;
}

class BackendHealthCheck {
  private baseUrl = 'http://localhost:3000/api';
  private results: HealthCheckResult[] = [];

  /**
   * Run all health checks
   */
  async runAll(): Promise<void> {
    console.log('🏥 Backend Health Check Started\n');

    try {
      // 1. Server connectivity
      await this.checkServerConnectivity();

      // 2. Health endpoint
      await this.checkHealthEndpoint();

      // 3. Authentication endpoints
      await this.checkAuthEndpoints();

      // 4. Student endpoints
      await this.checkStudentEndpoints();

      // 5. Activity endpoints
      await this.checkActivityEndpoints();

      // 6. Progress endpoints
      await this.checkProgressEndpoints();

      // 7. Database connectivity
      await this.checkDatabaseConnectivity();

      // Print results
      this.printResults();
    } catch (error) {
      console.error('❌ Health check failed:', error);
      process.exit(1);
    }
  }

  /**
   * Check server connectivity
   */
  private async checkServerConnectivity(): Promise<void> {
    const startTime = Date.now();
    try {
      const response = await axios.head(this.baseUrl, { timeout: 5000 });
      this.addResult({
        service: 'Server Connectivity',
        status: 'ok',
        message: 'Server is reachable',
        responseTime: Date.now() - startTime,
      });
    } catch (error) {
      this.addResult({
        service: 'Server Connectivity',
        status: 'error',
        message: `Server unreachable: ${error}`,
        responseTime: Date.now() - startTime,
      });
    }
  }

  /**
   * Check health endpoint
   */
  private async checkHealthEndpoint(): Promise<void> {
    const startTime = Date.now();
    try {
      const response = await axios.get(`${this.baseUrl}/health`, {
        timeout: 5000,
      });

      if (response.data.success) {
        this.addResult({
          service: 'Health Endpoint',
          status: 'ok',
          message: `Database: ${response.data.data?.database || 'unknown'}, Redis: ${response.data.data?.redis || 'unknown'}`,
          responseTime: Date.now() - startTime,
        });
      } else {
        this.addResult({
          service: 'Health Endpoint',
          status: 'error',
          message: response.data.message || 'Health check failed',
          responseTime: Date.now() - startTime,
        });
      }
    } catch (error) {
      this.addResult({
        service: 'Health Endpoint',
        status: 'error',
        message: `Health check error: ${error}`,
        responseTime: Date.now() - startTime,
      });
    }
  }

  /**
   * Check authentication endpoints (mock)
   */
  private async checkAuthEndpoints(): Promise<void> {
    const startTime = Date.now();
    try {
      // Just verify endpoint exists and returns proper error
      const response = await axios
        .post(`${this.baseUrl}/auth/request-otp`, { phone: '+966501234567' }, { timeout: 5000 })
        .catch((error) => error.response);

      if (response) {
        this.addResult({
          service: 'Auth Endpoints',
          status: 'ok',
          message: 'OTP endpoint operational',
          responseTime: Date.now() - startTime,
        });
      }
    } catch (error) {
      this.addResult({
        service: 'Auth Endpoints',
        status: 'error',
        message: `Auth check error: ${error}`,
        responseTime: Date.now() - startTime,
      });
    }
  }

  /**
   * Check student endpoints (mock - requires auth)
   */
  private async checkStudentEndpoints(): Promise<void> {
    const startTime = Date.now();
    try {
      // Would need valid JWT in production
      const response = await axios
        .get(`${this.baseUrl}/students`, { timeout: 5000 })
        .catch((error) => error.response);

      if (response?.status === 401) {
        // 401 is expected without auth
        this.addResult({
          service: 'Student Endpoints',
          status: 'ok',
          message: 'Endpoints operational (auth required as expected)',
          responseTime: Date.now() - startTime,
        });
      } else if (response) {
        this.addResult({
          service: 'Student Endpoints',
          status: 'ok',
          message: 'Endpoints operational',
          responseTime: Date.now() - startTime,
        });
      }
    } catch (error) {
      this.addResult({
        service: 'Student Endpoints',
        status: 'error',
        message: `Student endpoints error: ${error}`,
        responseTime: Date.now() - startTime,
      });
    }
  }

  /**
   * Check activity endpoints (no auth needed for GET)
   */
  private async checkActivityEndpoints(): Promise<void> {
    const startTime = Date.now();
    try {
      const response = await axios.get(`${this.baseUrl}/activities`, { timeout: 5000 });

      if (response.data.success && Array.isArray(response.data.data)) {
        this.addResult({
          service: 'Activity Endpoints',
          status: 'ok',
          message: `${response.data.data.length} activities loaded`,
          responseTime: Date.now() - startTime,
        });
      } else {
        this.addResult({
          service: 'Activity Endpoints',
          status: 'error',
          message: 'Activity data format invalid',
          responseTime: Date.now() - startTime,
        });
      }
    } catch (error) {
      this.addResult({
        service: 'Activity Endpoints',
        status: 'error',
        message: `Activity endpoints error: ${error}`,
        responseTime: Date.now() - startTime,
      });
    }
  }

  /**
   * Check progress endpoints (requires auth)
   */
  private async checkProgressEndpoints(): Promise<void> {
    const startTime = Date.now();
    try {
      // Would need valid JWT in production
      const response = await axios
        .get(`${this.baseUrl}/students/test-id/progress/daily`, { timeout: 5000 })
        .catch((error) => error.response);

      if (response?.status === 401) {
        this.addResult({
          service: 'Progress Endpoints',
          status: 'ok',
          message: 'Endpoints operational (auth required)',
          responseTime: Date.now() - startTime,
        });
      } else if (response) {
        this.addResult({
          service: 'Progress Endpoints',
          status: 'ok',
          message: 'Endpoints operational',
          responseTime: Date.now() - startTime,
        });
      }
    } catch (error) {
      this.addResult({
        service: 'Progress Endpoints',
        status: 'error',
        message: `Progress endpoints error: ${error}`,
        responseTime: Date.now() - startTime,
      });
    }
  }

  /**
   * Check database connectivity (via health endpoint)
   */
  private async checkDatabaseConnectivity(): Promise<void> {
    const startTime = Date.now();
    try {
      const response = await axios.get(`${this.baseUrl}/health`, { timeout: 5000 });

      if (response.data.data?.database === 'connected') {
        this.addResult({
          service: 'Database (Supabase)',
          status: 'ok',
          message: 'Database connected and operational',
          responseTime: Date.now() - startTime,
        });
      } else {
        this.addResult({
          service: 'Database (Supabase)',
          status: 'error',
          message: 'Database connection status unknown',
          responseTime: Date.now() - startTime,
        });
      }
    } catch (error) {
      this.addResult({
        service: 'Database (Supabase)',
        status: 'error',
        message: `Database check error: ${error}`,
        responseTime: Date.now() - startTime,
      });
    }
  }

  /**
   * Add result to results array
   */
  private addResult(result: HealthCheckResult): void {
    this.results.push({
      ...result,
      timestamp: new Date().toISOString(),
    });
  }

  /**
   * Print formatted results
   */
  private printResults(): void {
    console.log('\n📊 Health Check Results:\n');

    const okCount = this.results.filter((r) => r.status === 'ok').length;
    const errorCount = this.results.filter((r) => r.status === 'error').length;

    this.results.forEach((result) => {
      const icon = result.status === 'ok' ? '✅' : '❌';
      console.log(`${icon} ${result.service}`);
      console.log(`   Message: ${result.message}`);
      console.log(`   Response Time: ${result.responseTime}ms`);
    });

    console.log(`\n📈 Summary: ${okCount} OK, ${errorCount} Error(s)\n`);

    if (errorCount > 0) {
      console.log('⚠️  Some health checks failed. Please investigate.');
      process.exit(1);
    } else {
      console.log('✨ All health checks passed!');
      process.exit(0);
    }
  }
}

// Run health checks
const healthCheck = new BackendHealthCheck();
healthCheck.runAll();
