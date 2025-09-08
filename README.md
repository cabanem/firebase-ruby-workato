# Setup Development Environment for Workato SDK in IDX

## File Structure
```
.idx/
  ├── dev.nix
  └── idx.json
connector.rb
Gemfile
.gitignore
settings.yaml.example
setup.sh
README.md
```

## 1 `.idx/dev.nix`
```nix
{ pkgs, ... }: {
  packages = [
    pkgs.ruby_3_3
    pkgs.bundler
    pkgs.gcc
    pkgs.gnumake
    pkgs.git
    pkgs.openssl
  ];
  
  env = {
    BUNDLE_PATH = "vendor/bundle";
  };
  
  idx = {
    workspace = {
      onCreate = {
        setup = {
          runIn = "terminal";
          command = ''
            echo "Workato SDK Environment Ready"
            echo "Run ./setup.sh to initialize"
          '';
        };
      };
    };
  };
}
```

## 2 `.idx/idx.json`
```json
{
  "name": "Workato Connector Development",
  "icon": "https://raw.githubusercontent.com/devicons/devicon/master/icons/ruby/ruby-original.svg"
}
```

## 3 `setup.sh`
```bash
#!/bin/bash
# Simple Workato SDK Setup

echo "================================"
echo "  Workato SDK Setup"
echo "================================"
echo ""

# Configure bundler
bundle config set --local path 'vendor/bundle'
echo "✓ Bundle path configured"

# Install gems
if [ -f Gemfile ]; then
  echo "Installing gems..."
  bundle install
else
  echo "⚠️  No Gemfile found. Creating one..."
  bundle init
  echo "gem 'workato-connector-sdk', '~> 1.3.0'" >> Gemfile
  bundle install
fi

# Configure git
git config --global --add safe.directory "$(pwd)"
echo "✓ Git configured"

# Copy settings template if needed
if [ ! -f settings.yaml ] && [ -f settings.yaml.example ]; then
  cp settings.yaml.example settings.yaml
  echo "✓ Created settings.yaml from template"
  echo "⚠️  Edit settings.yaml with your credentials"
fi

echo ""
echo "Setup complete! Commands:"
echo "  workato exec test settings.yaml"
echo "  workato exec action <name> input.json settings.yaml"
echo "  bundle exec rspec"
echo ""
```

## 4 `Gemfile`
```ruby
source 'https://rubygems.org'

# Workato Connector SDK
gem 'workato-connector-sdk', '~> 1.3.0'

# Testing
group :test do
  gem 'rspec', '~> 3.12'
  gem 'webmock', '~> 3.18'
  gem 'vcr', '~> 6.2'
end

# Debugging
group :development do
  gem 'pry', '~> 0.14'
end
```

## 5 `connector.rb`
```ruby
{
  title: "My Connector",
  
  connection: {
    fields: [
      {
        name: "api_key",
        control_type: "password",
        label: "API Key",
        optional: false,
        hint: "Your API key from the platform"
      },
      {
        name: "subdomain",
        control_type: "text",
        label: "Subdomain",
        optional: false,
        hint: "Your account subdomain (e.g., 'mycompany')"
      }
    ],
    
    base_uri: lambda do |connection|
      "https://#{connection['subdomain']}.example.com/api/v1"
    end,
    
    authorization: {
      type: "custom_auth",
      
      apply: lambda do |connection|
        headers("Authorization": "Bearer #{connection['api_key']}")
      end
    }
  },
  
  test: lambda do |connection|
    get("/me")
  end,
  
  actions: {
    # Example action
    get_record: {
      title: "Get record",
      description: "Retrieves a single record by ID",
      
      input_fields: lambda do
        [
          { name: "id", type: "string", optional: false }
        ]
      end,
      
      output_fields: lambda do
        [
          { name: "id", type: "string" },
          { name: "name", type: "string" },
          { name: "created_at", type: "datetime" }
        ]
      end,
      
      execute: lambda do |connection, input|
        get("/records/#{input['id']}")
      end
    }
  },
  
  triggers: {
    # Example trigger
    new_record: {
      title: "New record",
      description: "Triggers when a new record is created",
      
      input_fields: lambda do
        []
      end,
      
      poll: lambda do |connection, input, closure|
        closure ||= { "last_id": 0 }
        
        records = get("/records", 
          since_id: closure["last_id"],
          limit: 100
        )
        
        next_closure = records.any? ? { "last_id": records.last["id"] } : closure
        
        {
          events: records,
          next_poll: next_closure
        }
      end,
      
      output_fields: lambda do
        [
          { name: "id", type: "string" },
          { name: "name", type: "string" },
          { name: "created_at", type: "datetime" }
        ]
      end
    }
  },
  
  object_definitions: {
    record: {
      fields: lambda do
        [
          { name: "id", type: "string" },
          { name: "name", type: "string" },
          { name: "description", type: "string" },
          { name: "created_at", type: "datetime" },
          { name: "updated_at", type: "datetime" }
        ]
      end
    }
  }
}
```

## 6 Example `settings.yaml.example`
```yaml
# Copy this file to settings.yaml and fill in your credentials
# DO NOT commit settings.yaml to version control

# Connection settings
api_key: your_api_key_here
subdomain: your_subdomain_here

# Optional: Environment
environment: sandbox  # or production
```

## 7 `.gitignore`
```gitignore
# Credentials - NEVER commit these
settings.yaml
settings.yml
.env
*.key
*.pem

# Bundle
vendor/bundle/
.bundle/

# Testing
spec/fixtures/vcr_cassettes/
coverage/
tmp/

# IDX
.idx/tmp/

# OS
.DS_Store
Thumbs.db

# Editor
*.swp
*.swo
*~
.vscode/
.idea/
```
## 8 `spec/connector_spec.rb`
```ruby
```ruby
require 'workato-connector-sdk'
require 'webmock/rspec'

RSpec.describe 'Connector' do
  let(:connector) { Workato::Connector::Sdk::Connector.from_file('./connector.rb') }
  let(:settings) { { api_key: 'test_key', subdomain: 'test' } }
  
  describe 'connection' do
    it 'has required fields' do
      fields = connector.connection.fields
      expect(fields.map { |f| f[:name] }).to include('api_key', 'subdomain')
    end
  end
  
  describe 'test connection' do
    it 'makes a GET request to /me' do
      stub_request(:get, 'https://test.example.com/api/v1/me')
        .to_return(status: 200, body: '{"status":"ok"}')
      
      result = connector.test(settings)
      expect(result).to eq({ "status" => "ok" })
    end
  end
  
  describe 'get_record action' do
    it 'retrieves a record by ID' do
      stub_request(:get, 'https://test.example.com/api/v1/records/123')
        .to_return(status: 200, body: '{"id":"123","name":"Test"}')
      
      result = connector.actions.get_record.execute(settings, { 'id' => '123' })
      expect(result['id']).to eq('123')
      expect(result['name']).to eq('Test')
    end
  end
end
```
---

# Getting Started
## Quick Start
1. Create the IDX structure (if necessary)
```bash
mkdir -p .idx
```
2. Copy files into project directory
3. Make setup script executable
```bash
chmod +x setup.sh
```
4. Run setup
```bash
./setup.sh
```
5. Add credentials to `settings.yaml`
6. Test your connection
```bash
workato exec test settings.yaml
```

## Common Commands

Testing connection:
- workato exec test settings.yaml

Testing an action:
- workato exec action get_record input.json settings.yaml

Testing a trigger:
- workato exec trigger new_record settings.yaml

Opening console:
- workato console

## Test Input
### Example input
Create input.json:
```json
    {
      "id": "12345"
    }
```

### Console Testing
```bash
# In the console
workato console

# Load and test
c = Workato::Connector::Sdk::Connector.from_file('./connector.rb')
settings = { api_key: 'test', subdomain: 'demo' }
c.actions.get_record.execute(settings, { id: '123' })
```

## Troubleshooting

SSL Issues:
```bash
export SSL_CERT_FILE=/etc/ssl/certs/ca-certificates.crt
```

Bundle Issues:
```bash
bundle config set --local path 'vendor/bundle'
bundle install --jobs 4
```

Permission Issues:
```bash
chmod +x setup.sh
```

## Quick Reference
Actions:
- workato exec action [name] [input] [settings]

Triggers:
- workato exec trigger [name] [settings]

Testing:
- bundle exec rspec
- workato check connector.rb

## Support
Check Workato SDK documentation for more details.

