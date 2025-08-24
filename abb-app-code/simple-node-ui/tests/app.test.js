const request = require('supertest');
const app = require('../src/app');

describe('API Tests', () => {
  it('should return the default message', async () => {
    const res = await request(app).get('/api/message');
    expect(res.statusCode).toBe(200);
    expect(res.body.message).toBe('Hello from Node.js App!');
  });

  it('should respond to health/live', async () => {
    const res = await request(app).get('/health/live');
    expect(res.statusCode).toBe(200);
  });

  it('should respond to health/ready', async () => {
    const res = await request(app).get('/health/ready');
    expect(res.statusCode).toBe(200);
  });
});
