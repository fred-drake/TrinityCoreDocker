const https = require('https');

const valueType = process.argv[2];
const branch = process.argv[3];

const options = {
    hostname: 'api.github.com',
    path: '/repos/TrinityCore/TrinityCore/releases',
    headers: { 'User-Agent': 'Mozilla/5.0' }
};

https.get(options, (resp) => {
    let data = '';

    resp.on('data', (chunk) => {
        data += chunk;
    });

    resp.on('end', () => {
        let obj = JSON.parse(data);
        for(let i=0; i<obj.length; i++) {
            if (obj[i]["target_commitish"] == branch) {
                if (valueType == 'path') {
                    process.stdout.write(obj[i]["assets"][0]["browser_download_url"]);
                } else if (valueType == 'file') {
                    process.stdout.write(obj[i]["assets"][0]["name"]);
                }
                return;
            }
        }
    });
}).on("error", (err) => {
    console.log("Error: " + err.message);
    process.exit(1)
});
