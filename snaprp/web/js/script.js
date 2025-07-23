document.addEventListener('DOMContentLoaded', () => {
    const storiesTab = document.getElementById('stories-tab');
    const profileTab = document.getElementById('profile-tab');
    const storiesContent = document.getElementById('stories-content');
    const profileContent = document.getElementById('profile-content');
    const cameraButton = document.getElementById('camera-button');
    const phoneContainer = document.getElementById('phone-container');

    // Mock user data for now
    const currentUser = {
        identifier: 'steam:110000100000000',
        username: 'Jules'
    };

    function switchTab(tabName) {
        storiesContent.style.display = 'none';
        profileContent.style.display = 'none';
        storiesTab.classList.remove('active');
        profileTab.classList.remove('active');

        if (tabName === 'stories') {
            storiesContent.style.display = 'block';
            storiesTab.classList.add('active');
            loadStories();
        } else if (tabName === 'profile') {
            profileContent.style.display = 'block';
            profileTab.classList.add('active');
            loadProfile(currentUser.identifier);
        }
    }

    storiesTab.addEventListener('click', () => switchTab('stories'));
    profileTab.addEventListener('click', () => switchTab('profile'));

    cameraButton.addEventListener('click', () => {
        fetch(`https://snaprp/openCamera`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json; charset=UTF-8' },
            body: JSON.stringify({})
        });
    });

    function loadStories() {
        fetch(`https://snaprp/getStories`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json; charset=UTF-8' },
            body: JSON.stringify({})
        }).then(resp => resp.json()).then(stories => {
            storiesContent.innerHTML = '';
            stories.forEach(story => {
                const storyElement = document.createElement('div');
                storyElement.className = 'story';
                storyElement.innerHTML = `
                    <div class="story-header">
                        <div class="story-avatar"></div>
                        <div class="story-username">${story.username}</div>
                    </div>
                    <div class="story-image-container">
                        <img class="story-image" src="${story.image_url}" alt="Story Image">
                        <div class="story-overlay">
                            <div class="story-overlay-username">${story.username}</div>
                            <div class="story-overlay-timestamp">${new Date(story.timestamp).toLocaleString()}</div>
                        </div>
                    </div>
                    <div class="story-actions">
                        <span class="story-action like-btn" data-story-id="${story.id}">❤️</span>
                        <span class="story-action comment-btn" data-story-id="${story.id}">💬</span>
                    </div>
                    <div class="story-likes">${story.likes} likes</div>
                    <div class="story-comments">View all ${story.comments.length} comments</div>
                `;
                storiesContent.appendChild(storyElement);
            });
        });
    }

    function loadProfile(identifier) {
        fetch(`https://snaprp/getPlayerProfile`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json; charset=UTF-8' },
            body: JSON.stringify({ identifier })
        }).then(resp => resp.json()).then(profile => {
            profileContent.innerHTML = `
                <div class="profile-header">
                    <div class="profile-avatar"></div>
                    <div class="profile-username">${profile.username}</div>
                    <div class="profile-status">"${profile.status || ''}"</div>
                </div>
                <div class="profile-streaks">
                    🔥 <strong>Daily Streak:</strong> ${profile.streak || 0}
                </div>
            `;
        });
    }

    storiesContent.addEventListener('click', (e) => {
        if (e.target.classList.contains('like-btn')) {
            const storyId = e.target.dataset.storyId;
            fetch(`https://snaprp/likeStory`, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json; charset=UTF-8' },
                body: JSON.stringify({ storyId })
            }).then(() => loadStories());
        } else if (e.target.classList.contains('comment-btn')) {
            const storyId = e.target.dataset.storyId;
            const comment = prompt("Enter your comment:");
            if (comment) {
                fetch(`https://snaprp/commentStory`, {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json; charset=UTF-8' },
                    body: JSON.stringify({ storyId, comment })
                }).then(() => loadStories());
            }
        }
    });

    window.addEventListener('message', (event) => {
        if (event.data.type === 'openPhone') {
            phoneContainer.style.display = 'block';
            switchTab('stories');
        } else if (event.data.type === 'stories') {
            const stories = event.data.stories;
            storiesContent.innerHTML = '';
            stories.forEach(story => {
                const storyElement = document.createElement('div');
                storyElement.className = 'story';
                storyElement.innerHTML = `
                    <div class="story-header">
                        <div class="story-avatar"></div>
                        <div class="story-username">${story.username}</div>
                    </div>
                    <img class="story-image" src="${story.image_url}" alt="Story Image">
                    <div class="story-actions">
                        <span class="story-action like-btn" data-story-id="${story.id}">❤️</span>
                        <span class="story-action comment-btn" data-story-id="${story.id}">💬</span>
                    </div>
                    <div class="story-likes">${story.likes} likes</div>
                    <div class="story-comments">View all ${story.comments.length} comments</div>
                `;
                storiesContent.appendChild(storyElement);
            });
        } else if (event.data.type === 'playerProfile') {
            const profile = event.data.profile;
            const streak = profile.streak || 0;
            const username = profile.username || currentUser.username;
            const status = profile.status || '';

            profileContent.innerHTML = `
                <div class="profile-header">
                    <div class="profile-avatar"></div>
                    <div class="profile-username">${username}</div>
                    <div class="profile-status">"${status}"</div>
                </div>
                <div class="profile-streaks">
                    🔥 <strong>Daily Streak:</strong> ${streak}
                </div>
            `;
        }
    });

    document.addEventListener('keydown', (e) => {
        if (e.key === 'Escape') {
            phoneContainer.style.display = 'none';
            fetch(`https://snaprp/close`, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json; charset=UTF-8' },
                body: JSON.stringify({})
            });
        }
    });

    // Initial load
    if (phoneContainer.style.display === 'block') {
        switchTab('stories');
    }
});
