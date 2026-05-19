class DefaultCategoryData {
  final String name;
  final String localizedName;
  final String icon;
  final List<String> keywords;

  const DefaultCategoryData({
    required this.name,
    required this.localizedName,
    required this.icon,
    required this.keywords,
  });
}

class DefaultCategories {
  static const List<DefaultCategoryData> all = [
    DefaultCategoryData(
      name: 'Code',
      localizedName: '코드',
      icon: 'code',
      keywords: [
        'func ', 'class ', 'struct ', 'import ', 'var ', 'let ', 'def ',
        'function', 'return ', 'if ', 'else ', 'for ', 'while ',
        'public ', 'private ', 'static ', 'void ', 'int ', 'string',
        'print(', 'console.log', 'System.out', 'println',
        'extension ', 'protocol ', 'enum ', 'switch ', 'case ',
        'try ', 'catch ', 'throw', 'async ', 'await ',
        'const ', 'export ', 'require(', 'module.',
        '//', '/*', '*/', '#include', '#import',
        'git ', 'npm ', 'pip ', 'brew ', 'cargo ',
        'Xcode', 'VSCode', 'IntelliJ', 'PyCharm', 'Sublime',
      ],
    ),
    DefaultCategoryData(
      name: 'Chat',
      localizedName: '채팅',
      icon: 'chat_bubble',
      keywords: [
        'iMessage', '카카오톡', 'KakaoTalk', 'Telegram', 'WhatsApp',
        'Slack', 'Discord', 'Teams', 'Messenger',
        '보냄', '읽음', '전송', '메시지',
        'sent', 'delivered', 'read', 'typing',
        '오전', '오후', 'AM', 'PM',
        '채팅', '대화', '메신저',
      ],
    ),
    DefaultCategoryData(
      name: 'Web',
      localizedName: '웹 브라우징',
      icon: 'language',
      keywords: [
        'http://', 'https://', 'www.', '.com', '.org', '.net', '.io',
        'Safari', 'Chrome', 'Firefox', 'Edge', 'Brave',
        '검색', 'Search', 'Google', 'Naver', '네이버', 'Daum', '다음',
        '탭', 'Tab', '북마크', 'Bookmark',
        '로그인', 'Sign in', 'Log in', '회원가입', 'Sign up',
        'URL', '주소창',
      ],
    ),
    DefaultCategoryData(
      name: 'Design',
      localizedName: '디자인',
      icon: 'brush',
      keywords: [
        'Figma', 'Sketch', 'Adobe', 'Photoshop', 'Illustrator',
        'XD', 'Canva', 'Framer', 'Zeplin',
        '레이어', 'Layer', '아트보드', 'Artboard',
        '색상', 'Color', '폰트', 'Font', 'Typography',
        'px', 'pt', 'em', 'rem', '#', 'RGB', 'HEX',
        '그리드', 'Grid', '컴포넌트', 'Component',
        '프로토타입', 'Prototype',
      ],
    ),
    DefaultCategoryData(
      name: 'Document',
      localizedName: '문서',
      icon: 'description',
      keywords: [
        'Word', 'Pages', 'Google Docs', 'Notion', '한글',
        '문서', 'Document', '제목', 'Title',
        '목차', 'Table of Contents',
        'PDF', 'xlsx', 'docx', 'pptx', 'hwp',
        '스프레드시트', 'Spreadsheet', 'Excel', 'Numbers',
        '프레젠테이션', 'Presentation', 'PowerPoint', 'Keynote',
        '메모', 'Notes', '노트', 'Bear', 'Obsidian',
      ],
    ),
    DefaultCategoryData(
      name: 'Terminal',
      localizedName: '터미널',
      icon: 'terminal',
      keywords: [
        'Terminal', '터미널', 'iTerm', 'Warp', 'Hyper',
        'zsh', 'bash', 'fish', 'shell',
        r'$ ', r'% ', r'# ', '❯', '➜',
        'sudo ', 'chmod ', 'chown ', 'mkdir ', 'rm ',
        'ls ', 'cd ', 'pwd', 'cat ', 'grep ',
        'docker ', 'kubectl ', 'ssh ', 'scp ',
        'brew ', 'apt ', 'yum ', 'pacman ',
      ],
    ),
    DefaultCategoryData(
      name: 'Image',
      localizedName: '이미지',
      icon: 'photo',
      keywords: [
        'Preview', '미리보기', 'Photos', '사진',
        'JPEG', 'PNG', 'GIF', 'SVG', 'WebP', 'HEIC',
        '이미지', 'Image', '사진', 'Photo',
        '갤러리', 'Gallery', '앨범', 'Album',
        '편집', 'Edit', '필터', 'Filter', '크롭', 'Crop',
      ],
    ),
    DefaultCategoryData(
      name: 'Video',
      localizedName: '영상',
      icon: 'play_circle',
      keywords: [
        'YouTube', '유튜브', 'Vimeo', 'Netflix', '넷플릭스',
        '동영상', 'Video', '재생', 'Play', '일시정지', 'Pause',
        'IINA', 'VLC', 'QuickTime',
        '스트리밍', 'Streaming', '라이브', 'Live',
        '구독', 'Subscribe', '채널', 'Channel',
        '자막', 'Subtitle', 'Caption',
      ],
    ),
    DefaultCategoryData(
      name: 'Other',
      localizedName: '기타',
      icon: 'grid_view',
      keywords: [],
    ),
  ];
}
