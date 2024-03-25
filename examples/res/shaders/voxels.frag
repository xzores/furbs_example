#version 330 core
in vec3 fNormal;
in vec3 fPos;

uniform vec2 resolution;
uniform mat4 inverseView;
uniform mat4 inverseProjection;
uniform vec3 cameraPos;
uniform vec3 lightColor;
uniform vec3 lightPos;
uniform sampler3D tex;

out vec4 FragColor;

float getVoxel(vec3 pos) {
    vec3 normalizedPos = (pos) / vec3(textureSize(tex, 0));
    return texture(tex, normalizedPos).a;
}

vec3 getVoxelColor(vec3 pos) {
    vec3 normalizedPos = (pos) / vec3(textureSize(tex, 0));
    return texture(tex, normalizedPos).rgb;
}

vec3 calculateRayDirection(vec2 fragCoord) {
    vec2 uv = fragCoord.xy / resolution.xy * 2.0 - 1.0;
    vec4 clipSpacePosition = vec4(uv, 1.0, 1.0);
    vec4 viewSpacePosition = inverseProjection * clipSpacePosition;
    viewSpacePosition.z = -1.0;
    viewSpacePosition.w = 0.0;
    vec3 worldSpaceDirection = normalize((inverseView * viewSpacePosition).xyz);
    return worldSpaceDirection;
}

vec3 calculateLighting(vec3 pos, vec3 normal, vec3 color) {
    vec3 ambient = 0.1 * color;

    vec3 lightDir = normalize(lightPos - pos);
    float diff = max(dot(normal, lightDir), 0.0);
    vec3 diffuse = diff * lightColor * color;

    vec3 viewDir = normalize(cameraPos - pos);
    vec3 reflectDir = reflect(-lightDir, normal);
    float spec = pow(max(dot(viewDir, reflectDir), 0.0), 32);
    vec3 specular = 0.5 * spec * lightColor;

    return ambient + diffuse + specular;
}

vec3 GetSurfaceNormal(vec3 p) {
    // Smooth normals by sampling voxels around the current position to compute the gradient
    float eps = 0.1;
    vec3 normal = vec3(
            getVoxel(p + vec3(eps, 0, 0)) - getVoxel(p - vec3(eps, 0, 0)),
            getVoxel(p + vec3(0, eps, 0)) - getVoxel(p - vec3(0, eps, 0)),
            getVoxel(p + vec3(0, 0, eps)) - getVoxel(p - vec3(0, 0, eps))
    );
    return normalize(normal);
}


void main() {
    vec3 rayPos = fPos; // -8,8,8
    vec3 rayDir = calculateRayDirection(gl_FragCoord.xy); //1,0,0.01 / 1,0,-0.01

    float voxelValue = 0.0;
    bool hit = false;
    vec3 color = vec3(1.0);
    vec3 normal = vec3(0.0);
    ivec3 voxelPos = ivec3(rayPos); //-8,8,8
    vec3 normDir = sign(rayDir);    //1,1,+/-
    int maxSteps = 20;

    /*
    if (normDir.x < 0) {
        voxelPos.x -= 1;
    }
    if (normDir.y < 0) {
        voxelPos.y -= 1;
    }
    if (normDir.z < 0) {
        voxelPos.z -= 1;
    }
    */
    
    for (int i = 0; i < maxSteps; i++) {
        float pX = vec3(voxelPos).x + (normDir.x + 1) / 2;
        float dX = abs((rayPos.x - pX) / rayDir.x);
        
        float pY = vec3(voxelPos).y + (normDir.y + 1) / 2;
        float dY = abs((rayPos.y - pY) / rayDir.y);
        
        float pZ = vec3(voxelPos).z + (normDir.z + 1) / 2;
        float dZ = abs((rayPos.z - pZ) / rayDir.z);
        
        float stepSize = min(dX, min(dY, dZ));
        
        if (dX < dY && dX < dZ) {
            voxelPos.x += int(normDir.x);
            normal = vec3(-normDir.x, 0.0, 0.0);
        }
        else if (dY < dX && dY < dZ) {
            voxelPos.y += int(normDir.y);
            normal = vec3(0.0, -normDir.y, 0.0);
        }
        else if (dZ < dX && dZ < dY) {
            voxelPos.z += int(normDir.z);
            normal = vec3(0.0, 0.0, -normDir.z);
        }
        else {
            voxelPos += ivec3(normDir);
            normal = -normDir;
        }
        
        rayPos += rayDir * stepSize;
        voxelValue = getVoxel(voxelPos);
        color = vec3(float(i) / float(maxSteps));
        if (voxelValue > 0.001) {
            color = getVoxelColor(voxelPos);
            hit = true;
            break;
        }
    }
    
    if (!hit) {
       discard;
    }
    
    FragColor = vec4(color, 1.0);
}