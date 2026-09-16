const request = require("supertest");
const app = require("../src/app");

describe("GET /status", () => {
  it("deve retornar status ok", async () => {
    const response = await request(app).get("/status");

    expect(response.statusCode).toBe(200);
    expect(response.body.status).toBe("ok");
  });
});
