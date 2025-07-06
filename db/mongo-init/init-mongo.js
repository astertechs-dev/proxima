// MongoDB Initialization Script for Proxima
// This script creates collections and indexes for MongoDB

// Switch to proxima database
db = db.getSiblingDB('proxima');

// Create collections with validation schemas

// Skill Sheets Collection
db.createCollection("skill_sheets", {
  validator: {
    $jsonSchema: {
      bsonType: "object",
      required: ["userId", "createdAt"],
      properties: {
        userId: {
          bsonType: "string",
          description: "User ID must be a string and is required"
        },
        rawText: {
          bsonType: "string",
          description: "Raw text of the uploaded skill sheet"
        },
        parsedData: {
          bsonType: "object",
          properties: {
            skills: {
              bsonType: "array",
              items: {
                bsonType: "string"
              }
            },
            experience: {
              bsonType: "array",
              items: {
                bsonType: "object",
                properties: {
                  company: { bsonType: "string" },
                  position: { bsonType: "string" },
                  duration: { bsonType: "string" },
                  description: { bsonType: "string" }
                }
              }
            },
            education: {
              bsonType: "array"
            },
            certifications: {
              bsonType: "array"
            }
          }
        },
        aiAnalysis: {
          bsonType: "object",
          properties: {
            skillLevel: { bsonType: "string" },
            recommendedImprovements: { bsonType: "array" },
            extractedKeywords: { bsonType: "array" }
          }
        },
        createdAt: {
          bsonType: "date",
          description: "Creation date is required"
        },
        updatedAt: {
          bsonType: "date"
        }
      }
    }
  }
});

// Portfolios Collection
db.createCollection("portfolios", {
  validator: {
    $jsonSchema: {
      bsonType: "object",
      required: ["userId", "createdAt"],
      properties: {
        userId: {
          bsonType: "string",
          description: "User ID must be a string and is required"
        },
        projects: {
          bsonType: "array",
          items: {
            bsonType: "object",
            properties: {
              title: { bsonType: "string" },
              description: { bsonType: "string" },
              technologies: {
                bsonType: "array",
                items: { bsonType: "string" }
              },
              githubUrl: { bsonType: "string" },
              liveUrl: { bsonType: "string" },
              images: {
                bsonType: "array",
                items: { bsonType: "string" }
              }
            }
          }
        },
        githubIntegration: {
          bsonType: "object",
          properties: {
            username: { bsonType: "string" },
            repositories: { bsonType: "array" },
            lastSynced: { bsonType: "date" }
          }
        },
        createdAt: {
          bsonType: "date",
          description: "Creation date is required"
        },
        updatedAt: {
          bsonType: "date"
        }
      }
    }
  }
});

// Activity Logs Collection
db.createCollection("activity_logs", {
  validator: {
    $jsonSchema: {
      bsonType: "object",
      required: ["userId", "action", "timestamp"],
      properties: {
        userId: {
          bsonType: "string",
          description: "User ID must be a string and is required"
        },
        action: {
          bsonType: "string",
          description: "Action type is required"
        },
        targetId: {
          bsonType: "string",
          description: "Target resource ID"
        },
        metadata: {
          bsonType: "object",
          description: "Additional metadata for the action"
        },
        timestamp: {
          bsonType: "date",
          description: "Timestamp is required"
        }
      }
    }
  }
});

// AI Training Data Collection
db.createCollection("ai_training_data", {
  validator: {
    $jsonSchema: {
      bsonType: "object",
      required: ["type", "data", "createdAt"],
      properties: {
        type: {
          bsonType: "string",
          enum: ["skill_extraction", "job_matching", "text_enhancement"],
          description: "Type of training data"
        },
        data: {
          bsonType: "object",
          description: "Training data object"
        },
        labels: {
          bsonType: "array",
          description: "Labels for supervised learning"
        },
        createdAt: {
          bsonType: "date",
          description: "Creation date is required"
        }
      }
    }
  }
});

// Recommendations Collection
db.createCollection("recommendations", {
  validator: {
    $jsonSchema: {
      bsonType: "object",
      required: ["userId", "type", "items", "createdAt"],
      properties: {
        userId: {
          bsonType: "string",
          description: "User ID is required"
        },
        type: {
          bsonType: "string",
          enum: ["job_recommendations", "candidate_recommendations"],
          description: "Type of recommendation"
        },
        items: {
          bsonType: "array",
          items: {
            bsonType: "object",
            properties: {
              itemId: { bsonType: "string" },
              score: { bsonType: "double" },
              reasons: { bsonType: "array" }
            }
          }
        },
        algorithm: {
          bsonType: "string",
          description: "Algorithm used for recommendation"
        },
        createdAt: {
          bsonType: "date",
          description: "Creation date is required"
        },
        expiresAt: {
          bsonType: "date",
          description: "Expiration date for recommendations"
        }
      }
    }
  }
});

// Create indexes for better performance

// Skill Sheets indexes
db.skill_sheets.createIndex({ "userId": 1 });
db.skill_sheets.createIndex({ "createdAt": -1 });
db.skill_sheets.createIndex({ "parsedData.skills": 1 });

// Portfolios indexes
db.portfolios.createIndex({ "userId": 1 });
db.portfolios.createIndex({ "createdAt": -1 });
db.portfolios.createIndex({ "projects.technologies": 1 });

// Activity Logs indexes
db.activity_logs.createIndex({ "userId": 1 });
db.activity_logs.createIndex({ "timestamp": -1 });
db.activity_logs.createIndex({ "action": 1 });
db.activity_logs.createIndex({ "targetId": 1 });

// AI Training Data indexes
db.ai_training_data.createIndex({ "type": 1 });
db.ai_training_data.createIndex({ "createdAt": -1 });

// Recommendations indexes
db.recommendations.createIndex({ "userId": 1 });
db.recommendations.createIndex({ "type": 1 });
db.recommendations.createIndex({ "createdAt": -1 });
db.recommendations.createIndex({ "expiresAt": 1 }, { expireAfterSeconds: 0 });

// Insert sample data for development

// Sample skill sheet
db.skill_sheets.insertOne({
  userId: "sample-user-id-1",
  rawText: "フロントエンドエンジニア 5年の経験 React, TypeScript, Next.js",
  parsedData: {
    skills: ["React", "TypeScript", "Next.js", "JavaScript", "HTML", "CSS"],
    experience: [
      {
        company: "株式会社サンプル",
        position: "フロントエンドエンジニア",
        duration: "2020-01 to 2024-12",
        description: "React.jsを用いたWebアプリケーション開発"
      }
    ],
    education: [],
    certifications: []
  },
  aiAnalysis: {
    skillLevel: "senior",
    recommendedImprovements: ["バックエンド技術の習得", "クラウド技術の学習"],
    extractedKeywords: ["React", "TypeScript", "フロントエンド", "Webアプリケーション"]
  },
  createdAt: new Date(),
  updatedAt: new Date()
});

// Sample portfolio
db.portfolios.insertOne({
  userId: "sample-user-id-1",
  projects: [
    {
      title: "ECサイト構築",
      description: "React + Node.jsによるECサイト",
      technologies: ["React", "Node.js", "MongoDB", "Express.js"],
      githubUrl: "https://github.com/sample/ecommerce-site",
      liveUrl: "https://sample-ecommerce.com",
      images: ["https://example.com/image1.jpg", "https://example.com/image2.jpg"]
    },
    {
      title: "タスク管理アプリ",
      description: "Next.js + TypeScriptによるタスク管理アプリケーション",
      technologies: ["Next.js", "TypeScript", "PostgreSQL", "Prisma"],
      githubUrl: "https://github.com/sample/task-manager",
      liveUrl: "https://sample-tasks.com",
      images: ["https://example.com/task1.jpg"]
    }
  ],
  githubIntegration: {
    username: "sampleuser",
    repositories: [],
    lastSynced: new Date()
  },
  createdAt: new Date(),
  updatedAt: new Date()
});

// Sample activity logs
db.activity_logs.insertMany([
  {
    userId: "sample-user-id-1",
    action: "job_view",
    targetId: "job-id-1",
    metadata: {
      jobTitle: "React開発者募集",
      searchQuery: "React リモート",
      userAgent: "Mozilla/5.0...",
      ipAddress: "192.168.1.1"
    },
    timestamp: new Date()
  },
  {
    userId: "sample-user-id-1",
    action: "profile_update",
    targetId: "sample-user-id-1",
    metadata: {
      updatedFields: ["bio", "skills"],
      previousValues: {}
    },
    timestamp: new Date()
  }
]);

print("MongoDB initialization completed successfully!");
print("Created collections: skill_sheets, portfolios, activity_logs, ai_training_data, recommendations");
print("Created indexes for optimal performance");
print("Inserted sample data for development");
